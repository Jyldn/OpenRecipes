(ql:quickload '(dexador jsown markdown.cl cl-ppcre) :silent t)

(defun write-to-file (path str)
  (with-open-file (file path
			:direction :output
			:if-exists :supersede
			:if-does-not-exist :create)
    (format file str)))

(defun meal-db-recipes ()
  (loop for c from 97 upto 122
	collect
	(jsown:parse
	 (dex:get (concatenate 'string "https://www.themealdb.com/api/json/v1/1/search.php?f="
			       (string (code-char c)))))))

(defun mealdb-regex-r (instructions)
  (setf instructions (ppcre:regex-replace-all "((\\s*)?STEP \\d\\r\\n|\\.?\\r\\n(\\r\\n)?)" instructions (format nil "~%- ")))
  (setf instructions (ppcre:regex-replace-all "- \\n" instructions ""))
  instructions)

(defun mealdb2md (data path)
  (loop for meal in (jsown:val data "meals")
	do
	   (write-to-file
	    (merge-pathnames path (concatenate 'string (jsown:val meal "strMeal") ".md"))
	    (format nil
		"!Name: ~A~%~%Description:~%![~A](~A \"~A\")~%~%Ingredients:~%~{- ~A~%~}~%Directions:~%- ~A~%"
		(jsown:val meal "strMeal")
		(jsown:val meal "strMeal")
		(jsown:val meal "strMealThumb")
		(jsown:val meal "strMeal")
		(loop for i from 1 upto 20
		      when (let ((meal (jsown:val meal (format nil "strIngredient~A" i))))
			     (not (or (null meal) (string= meal ""))))
		      collect  (jsown:val-safe meal (format nil "strIngredient~A" i)))
		(mealdb-regex-r (jsown:val meal "strInstructions"))))))


(defmacro replace-heading (regex buf form)
  `(setf ,buf (ppcre:regex-replace-all ,regex
				       ,buf
				       #'(lambda (match &rest registers)
					   (declare (ignore match))
					   (format nil ,form (car registers)))
				       :simple-calls t)))

(defun read-file-string (path)
  (if (probe-file path)
      (uiop:read-file-string path)))

(defun md2html (path outdir)
  (let* ((buf (markdown:parse-file path))
	 (title (multiple-value-bind (match title)
		    (ppcre:scan-to-strings "!Name:\\s?([\\w ]*)" buf)
		  (declare (ignore match))
		  (aref title 0)))
	 (init-with-title (ppcre:regex-replace "<//head>"
					       (read-file-string "recipes/init.html")
					       (concatenate 'string "<title>" title "</title>" "</head>")))
	 (outpath (merge-pathnames outdir (concatenate 'string title ".html"))))

    (replace-heading "!Name:\\s?([\\w ]*)" buf "<h1>~A</h1>")
    (replace-heading "!Author:\\s?([\\w ]*)" buf "<h2>Author: ~A</h2>")
    (setf buf (ppcre:regex-replace-all "(Description|Directions|Ingredients|Closing Remarks):" buf "<h2>\\&</h2>"))
    (write-to-file outpath (concatenate 'string init-with-title buf (read-file-string "recipes/end.html")))))

(defun md2html-all (path)
  (loop for file in (directory path)
        do
        (format t "Converting ~A~%" file)
        (md2html file #p"www/recipes/")))

(format t "Converting all .md to .html~%")
(md2html-all #p"recipes/*.md")
(format t "Done converting all .md to .html~%")
(quit)
