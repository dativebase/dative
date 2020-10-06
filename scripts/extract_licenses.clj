(ns extract-licenses)

(require '[clojure.string :as str]
         '[clojure.java.shell :as shell]
         '[cheshire.core :as json]
         '[clojure.java.io :as io]
         '[clojure.pprint :as pprint])

(defn just [x] [x nil])

(defn nothing [error] [nil error])

(defn bind
  "Call f on val if err is nil, otherwise return [nil err]
  See https://adambard.com/blog/acceptable-error-handling-in-clojure/."
  [f [val err]]
  (if (nil? err)
    (f val)
    [nil err]))

(defmacro err->>
  "Thread-last val through all fns, each wrapped in bind.
  See https://adambard.com/blog/acceptable-error-handling-in-clojure/."
  [val & fns]
  (let [fns (for [f fns] `(bind ~f))]
    `(->> [~val nil]
          ~@fns)))

(defn update-hist [old-hist {:keys [exit] :as o} cmd descr]
  (conj old-hist
        (merge o {:cmd cmd
                  :summary (if (= 0 exit)
                             (format "Succeeded: %s." descr)
                             (format "Failed: %s." descr))})))

(defn remove-all-trailing-slashes [path]
  (loop [path path]
    (if (= \/ (last path))
      (recur (->> path butlast (apply str)))
      path)))

(defn ensure-trailing-slash [path]
  (-> path
      remove-all-trailing-slashes
      (str "/")))

(defn path-join [& parts] (str/join "/" (map remove-all-trailing-slashes parts)))

(defn get-dirname [path]
  (->> (str/split path #"/") butlast (str/join "/")))

(def script-path *file*)

(def script-dir (get-dirname script-path))

(def root-dir (get-dirname script-dir))

(def root-git-dir (path-join root-dir ".git"))

(def releases-dir (path-join root-dir "releases"))

(defn run-shell-cmd [ctx cmd descr]
  (let [{:keys [exit] :as o} (apply shell/sh cmd)]
    ((if (= 0 exit) just nothing)
     (do
       (when (not= 0 exit) (pprint/pprint o))
       (update ctx :history update-hist o cmd descr)))))

(defn shell-out-git-commit [ctx]
  (run-shell-cmd
   ctx
   ["git"
    "--git-dir=/Users/joeldunham/Development/dativetop/dativetop/src/dative/.git"
    "rev-parse" "HEAD"]
   "Get the most recent commit of Dative."))

(defn parse-and-set-git-commit [ctx]
  (just (assoc
         ctx
         :git-commit
         (-> ctx :history first :out str/trim))))

(defn set-git-tip-hash [ctx]
  (err->> ctx
          shell-out-git-commit
          parse-and-set-git-commit))

(defn set-release-dir [{:as ctx :keys [git-commit]}]
  (just
   (assoc ctx
          :release-dir
          (path-join releases-dir (str "release-" git-commit)))))

(defn check-if-release-dir-exists [{:as ctx :keys [release-dir]}]
    (just (assoc ctx :release-dir-exists?
                 (and (.exists (io/file release-dir))
                      (.isDirectory (io/file release-dir))))))

(defn create-release-dir* [{:as ctx :keys [release-dir release-dir-exists?]}]
  (when-not release-dir-exists?
    (.mkdir (io/file release-dir))
    (.mkdir (io/file (path-join release-dir "licenses"))))
  (just ctx))

(defn create-release-dir [ctx]
  (err->> ctx
         set-release-dir
         check-if-release-dir-exists
         create-release-dir*))

(defn write-licenses [{:as ctx :keys [release-dir]}]
  (let [path (path-join release-dir "licenses" "licenses.json")]
  (run-shell-cmd
   (assoc ctx :licences-json-path path)
   ["npm-license-crawler" "--dependencies" "--json" path]
   "Identify the Dative depdendency licenses using npm-license-crawler")))

(defn parse-licenses [{:as ctx path :licences-json-path}]
  (just
   (assoc
    ctx
    :licenses
    (-> path slurp (json/parse-string true)))))

(defn identify-licenses [ctx]
  (err->> ctx
          write-licenses
          parse-licenses))

(defn download-licenses [{:as ctx :keys [release-dir licenses]}]
  (doseq [[license-name {license-url :licenseUrl}] licenses]
    (.mkdir (io/file (path-join release-dir (name license-name))))
    (when-let [license (try (slurp license-url) (catch Exception _ nil))]
      (spit
       (path-join release-dir (name license-name) "LICENSE")
       license)))
    (just ctx))

(defn main
  "Does the following:
  1. identify the hash of the HEAD commit of the current Dative and create a
     ``release-<HASH>/`` directory under ``releases/``;
  2. shell out to npm-license-crawler to write
     ``releases/release-<HASH>/licenses/licenses/licenses.json``, a JSON file
     identifying all dependencies and the URLs of their licenses; and
  3. make an HTTP GET request for each license URL and save the license text to
     a files at paths like ``releases/release-<HASH>/<DEPENDENCY_ID>/LICENSE``.
  Note: call ``(get-not-found-licenses)`` to identify the dependencies whose
  licenses could not be found and attempt to manually identify the license."
  []
  (err->> {}
          set-git-tip-hash
          create-release-dir
          identify-licenses
          download-licenses)
  (println "Done"))

(defn get-not-found-licenses* [{:as ctx :keys [release-dir licenses]}]
  (doseq [[license-name {repo :repository license-url :licenseUrl}] licenses]
    (let [dep-dir (path-join release-dir (name license-name))
          license-path (path-join dep-dir "LICENSE")]
      (when-not (.exists (io/file license-path))
        (printf "%s\n  %s\n  %s\n\n"
                (name license-name)
                license-url
                repo))))
  (just ctx))

(defn get-not-found-licenses []
  (err->> {}
          set-git-tip-hash
          create-release-dir
          identify-licenses
          get-not-found-licenses*)
  (println "Done"))

;; (main)

(get-not-found-licenses)

;; Create the release archive::
;;
;;     $ tar -zcvf release-2c18bdf158fc8664404e67e5530b9a95a18d6d11.tar.gz release-2c18bdf158fc8664404e67e5530b9a95a18d6d11
