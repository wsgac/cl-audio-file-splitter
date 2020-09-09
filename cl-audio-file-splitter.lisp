;;;; cl-audio-file-splitter.lisp

(in-package #:cl-audio-file-splitter)

(defparameter *encoding-backend* :ffmpeg)
(defparameter *allowed-encoding-backends* '(:ffmpeg))
(defparameter *id3-backend* :id3ed)
(defparameter *allowed-id3-backend* '(:id3ed :mp3info))

(defun duration-p (duration)
  "Check if DURATION conforms to the [hh:][mm:]ss spec."
  (and (stringp duration)
       (cl-ppcre:scan "^([0-9]+:)?([0-5]?[0-9]:)?([0-5]?[0-9])$" duration)))

(defun parse-duration (duration)
  "Parse the duration string, expected to be in the form [hh:][mm:]ss
and convert it to seconds."
  (assert (duration-p duration))
  (reduce #'(lambda (xx x) (+ x (* 60 xx)))
	  (mapcar #'(lambda (x) (parse-integer x :junk-allowed t))
		  (cl-ppcre:split ":" duration))))

(defun validate-duration-spec (spec)
  "Verify that SPEC is a valid duration specification, i.e. a list of
  the form '((\"Title 1\" . \"<duration-1>\") (\"Title 2\"
  . \"<duration-2>\") ...)."
  (and (listp spec)
       (every #'(lambda (item)
		  (and (stringp (car item))
		       (duration-p (cdr item)))) spec)))

(defun convert-durations-to-timestamps (durations)
  "Given a duration spec, calculate time ranges for each part and
return a list of (title start end) lists."
  (loop
     for (title . duration-str) in durations
     for duration = (parse-duration duration-str)
     for start = 0 then end
     for end = (+ start duration)
     collect (list title start end)))

(defun extract-fragment-from-file (input-file output-file title track start end)
  "Take INPUT-FILE and extract the part delimited by START and END
into OUTPUT-FILE. Adjust the Title and Track ID3 tags on OUTPUT-FILE
to TITLE and TRACK respectively."
  (assert (<= start end))
  (uiop:delete-file-if-exists output-file)
  ;; Extraction proper
  (uiop:run-program (generate-extraction-command
		     *encoding-backend*
		     :input-file input-file :output-file output-file :start start :end end)
		    :output t)
  ;; ID3 tag adjustment
  (uiop:run-program (generate-id3-command
		     *id3-backend* output-file
		     :title title
		     :track (princ-to-string track))))

(defun split-single-file-into-parts (file spec output-directory &key prepend-track-to-files)
  "Take FILE and SPEC (specification of parts) and split FILE
accordingly, placing the resulting files in OUTPUT-DIRECTORY. If
PREPEND-TRACK-TO-FILES is not NIL, prepend track numbers to
filenames."
  (assert (validate-duration-spec spec))
  (assert (member *id3-backend* *allowed-id3-backend*))
  (assert (member *encoding-backend* *allowed-encoding-backends*))
  (assert (uiop:file-exists-p file))
  (uiop/common-lisp:ensure-directories-exist output-directory)
  (let ((part-timestamps (convert-durations-to-timestamps spec))
	(output-directory-final (namestring
				 (uiop:truename*
				  (uiop:ensure-directory-pathname output-directory)))))
    (loop
       for i from 1
       for (title start end) in part-timestamps
       for output-path = (format nil "~a~:[~*~;~2,'0d - ~]~a.mp3" output-directory-final prepend-track-to-files i title)
       do
	 (format t "Extracting part: ~a~%" title)
	 (extract-fragment-from-file file output-path title i start end))))

;;;;;;;;;;;;;;
;; Encoding ;;
;;;;;;;;;;;;;;

;; FFMPEG-specific code

(defmethod generate-extraction-command ((backend (eql :ffmpeg)) &key input-file output-file start end)
  (list "ffmpeg"
	"-i" input-file
	"-acodec" "copy"
	"-ss" (prin1-to-string start)
	"-to" (prin1-to-string end)
	output-file))

;;;;;;;;;;;;;;
;; ID3 Tags ;;
;;;;;;;;;;;;;;

;; mp3info-specific code

(defmethod generate-id3-command ((backend (eql :mp3info)) file &key title artist album track)
  `("mp3info"
    ,@(if title (list "-t" title))
    ,@(if artist (list "-a" artist))
    ,@(if album (list "-l" album))
    ,@(if track (list "-n" track))
    ,file))

;; id3ed-specific code

(defmethod generate-id3-command ((backend (eql :id3ed)) file &key title artist album track)
  `("id3ed"
    "-q"
    ,@(if title (list "-s" title))
    ,@(if artist (list "-n" artist))
    ,@(if album (list "-a" album))
    ,@(if track (list "-k" track))
    ,file))

;; (defparameter *example-part-specification*
;;   '(("Part 1" . "9:55")
;;     ("Part 2" . "8:33")
;;     ("Part 3" . "8:12")
;;     ("Part 4" . "9:40")
;;     ("Part 5" . "3:55")
;;     ("Part 6" . "3:54")
;;     ("Part 7" . "6:46")))
