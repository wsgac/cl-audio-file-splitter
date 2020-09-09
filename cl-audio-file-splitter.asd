;;;; cl-audio-file-splitter.asd

(asdf:defsystem #:cl-audio-file-splitter
  :description "A tiny Common Lisp utility for splitting audio files based on temporal description"
  :author "Wojciech S. Gac <wojciech.s.gac@gmail.com>"
  :license  "GPLv3"
  :version "0.0.1"
  :serial t
  :depends-on (#:cl-ppcre)
  :components ((:file "package")
               (:file "cl-audio-file-splitter")))
