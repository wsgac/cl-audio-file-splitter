;;;; package.lisp

(defpackage #:cl-audio-file-splitter
  (:use #:cl)
  (:export #:*encoding-backend*
	   #:*id3-backend*
	   #:split-single-file-into-parts))
