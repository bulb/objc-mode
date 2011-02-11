; -*- Mode: Lisp; Package: EDITOR -*-
; objc-mode.l Objective-C mode

;; Copyright (c) 2007-2011 bulb.
;;
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
;; LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
;; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
;; WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#|
(export 'ed::objc-mode "ed")
(autoload 'objc-mode "objc-mode" t)
(pushnew '("\\.m$" . objc-mode) *auto-mode-alist* :test 'equal)
|#

;;; Code:

(provide "objc-mode")

(in-package "editor")

(eval-when (:compile-toplevel :load-toplevel :execute)
  (export '(objc-mode
#|
            objc-indent-level
            objc-continued-statement-offset
            objc-argdecl-indent
            objc-brace-offset
            objc-brace-imaginary-offset
            objc-label-offset
            objc-comment-indent
            objc-newline-and-indent
            objc-indent-line
            objc-indent-of-a-line
            decode-c-mode2
|#
            )))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (export '(*objc-mode-hook*
            *objc-comment-column*
            *objc-keyword-file*
            *objc-indent-tabs-mode*
            )))

(defvar *objc-mode-hook* nil)

(defconstant *syntax-option-indent-objc* 4)

(unless (boundp 'objc-indent-level)
  (setq objc-indent-level 4)
  (setq objc-continued-statement-offset 4)
  (setq objc-argdecl-indent 4)
  (setq objc-brace-offset 0)
  (setq objc-brace-imaginary-offset 0)
  (setq objc-label-offset -4)
  (setq objc-comment-indent 4))

(defvar *objc-keyword-hash-table* nil)
(defvar *objc-keyword-file* "ObjC")

(defvar *objc-indent-tabs-mode* nil)
(defvar *objc-comment-column* nil)

(defvar *objc-mode-syntax-table* nil)
(unless *objc-mode-syntax-table*
  (setq *objc-mode-syntax-table* (make-syntax-table))
  (do ((x #x21 (1+ x)))((>= x #x7f))
    (let ((c (code-char x)))
      (unless (alphanumericp c)
        (set-syntax-punctuation *objc-mode-syntax-table* c))))
;  (set-syntax-option *objc-mode-syntax-table*
;                     (+ *syntax-option-c-preprocessor*
;                        *syntax-option-indent-objc*))
  (set-syntax-string *objc-mode-syntax-table* #\")
  (set-syntax-string *objc-mode-syntax-table* #\')
  (set-syntax-escape *objc-mode-syntax-table* #\\)
  (set-syntax-symbol *objc-mode-syntax-table* #\_)
  (set-syntax-symbol *objc-mode-syntax-table* #\#)
  (set-syntax-symbol *objc-mode-syntax-table* #\@)
  (set-syntax-match *objc-mode-syntax-table* #\( #\))
  (set-syntax-match *objc-mode-syntax-table* #\{ #\})
  (set-syntax-match *objc-mode-syntax-table* #\[ #\])
  (set-syntax-start-multi-comment *objc-mode-syntax-table* "/*")
  (set-syntax-end-multi-comment *objc-mode-syntax-table* "*/")
  (set-syntax-start-c++-comment *objc-mode-syntax-table* #\/)
  (set-syntax-end-c++-comment *objc-mode-syntax-table* #\LFD)
  )

(defvar *objc-mode-map* nil)
(unless *objc-mode-map*
  (setq *objc-mode-map* (make-sparse-keymap))
  (define-key *objc-mode-map* #\{ 'c-electric-insert)
  (define-key *objc-mode-map* #\: 'objc-electric-insert)
  (define-key *objc-mode-map* #\# 'c-electric-insert)
  (define-key *objc-mode-map* #\@ 'c-electric-insert)
  (define-key *objc-mode-map* #\} 'c-electric-close)
  (define-key *objc-mode-map* #\C-h 'backward-delete-char-untabify-or-selection)
  (define-key *objc-mode-map* #\TAB 'objc-indent-line)
  (define-key *objc-mode-map* #\C-M-q 'indent-sexp)
  (define-key *objc-mode-map* #\RET 'objc-newline-and-indent))


(defvar *objc-mode-abbrev-table* nil)
(unless *objc-mode-abbrev-table*
  (define-abbrev-table '*objc-mode-abbrev-table*))


(defvar *objc-keyword-0* '(:keyword 0))
(defvar *objc-keyword-1* '(:keyword 1))
(defvar *objc-keyword-2* '(:keyword 2))

(defvar *objc-variables-format* nil)
(setq *objc-variables-format*
      (compile-regexp-keyword-list
       `(("\\<\\(NS\\|CF\\)[a-zA-Z0-9]+" nil ,*objc-keyword-0*)
         )))


;;;
;;;###autoload
;;;
(defun objc-mode ()
  "Major mode for editing Objective C code."
  (interactive)
  (kill-all-local-variables)
  (setq mode-name "ObjC")
  (setq buffer-mode 'objc-mode)
  (use-syntax-table *objc-mode-syntax-table*)
  (use-keymap *objc-mode-map*)

  (make-local-variable 'mode-specific-indent-command)
  (setq mode-specific-indent-command 'c-indent-line)
  (make-local-variable 'c-comment-indent-variable)
  (setq c-comment-indent-variable 'objc-comment-indent)

  (make-local-variable 'paragraph-start)
  (setq paragraph-start "^$\\|\f")
  (make-local-variable 'paragraph-separate)
  (setq paragraph-separate paragraph-start)
  (make-local-variable 'indent-tabs-mode)
  (setq indent-tabs-mode *objc-indent-tabs-mode*)

  (make-local-variable 'tags-find-target)
  (setq tags-find-target #'c-tags-find-target)
  (make-local-variable 'tags-find-point)
  (setq tags-find-point #'c-tags-find-point)

  (make-local-variable 'build-summary-function)
  (setq build-summary-function 'c-build-summary-of-functions)

  (make-local-variable 'regexp-keyword-list)
  (setq regexp-keyword-list *objc-variables-format*)

  (and *objc-keyword-file*
       (null *objc-keyword-hash-table*)
       (setq *objc-keyword-hash-table*
             (load-keyword-file *objc-keyword-file*)))
  (when *objc-keyword-hash-table*
    (make-local-variable 'keyword-hash-table)
    (setq keyword-hash-table *objc-keyword-hash-table*))

  (setq *local-abbrev-table* *objc-mode-abbrev-table*)
  (setq comment-start "// "
        comment-end ""
        comment-start-skip "/\\(\\*+\\|/\\)[ \t]*"
        comment-indent-function 'c-comment-indent)
  (when *objc-comment-column*
    (setq comment-column *objc-comment-column*))
  (run-hooks '*objc-mode-hook*))

;;; objc-mode.l ends here
