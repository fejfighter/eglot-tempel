;;; eglot-tempel.el --- Use tempel to expand snippets from eglot -*- lexical-binding: t -*-

;; Copyright (C) 2022-2023 Jeffrey Walsh

;; Author: Jeff Walsh <fejfighter@gmail.com>
;; Created: 2022
;; Version: 0.8
;; Package-Requires: ((eglot "1.9")  (tempel "0.5") (emacs "29.1") (peg "1.0.1"))
;; Keywords: convenience, languages, tools
;; URL: https://github.com/fejfighter/eglot-tempel

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; LSP can provide inline/template hinting for function completion,
;; Currently eglot only checks for yasnippet to enable this
;; feature.  This package patches the function or mocks yasnippet
;; (depending on what is installed) to use tempel.el for that feature
;; by translating the LSP template into a sexp used by tempel.el

(require 'tempel)
(require 'eglot)
(require 'peg)

;;; Code:
(defun eglot-tempel--peg (snippet)
  "Parse lsp-server provided SNIPPET and produce a Lisp form that tempel can use."
  (with-temp-buffer
    (insert snippet)
    (goto-char (point-min))
    (with-peg-rules
	((snippet (* (or anything text)))
	 (anything (or tabstop
		       braced
		       placeholder
		       choice
		       dots))
	 (tabstop (and "$" int )  `(num -- (if (= 0 num) 'q 'p)))
	 (braced (and "${" int "}") `(num --  (if (= 0 num) 'q 'p)))
	 (placeholder (and "${" int ":" (or anything name) "}")
		      `(num place -- (let ((placeholder (if (string-empty-p place)
							    "_"
							  place)))
				       `(p ,placeholder ,num))))
	 (choice  (and "${" int "|" text "|}" `(num choices -- `(p ,choices ,num))))
	 (dots "..." `( -- `(p "...")))
	 (int (substring (+ [0-9])) `(num -- (string-to-number num)))
	 (text (substring (+ char)))
	 (name (substring (* char)))
	 (char (not end) (any))
	 (end  (or (set "$}|") (eob))))
      (peg-run (peg snippet)))))

(defun eglot-tempel--convert (snippet)
  "Convert a SNIPPET returned from Eglot into a format useful for tempel."
  `( ,@(reverse (eglot-tempel--peg snippet)) q))

(defun eglot-tempel-expand-yas-snippet (snippet &optional START END EXPAND-ENV)
  "Emulate yasnippet expansion function call.
SNIPPET - snippet for converting.
START END EXPAND-ENV are all ignored."
  (ignore START END EXPAND-ENV)
  (when eglot-tempel-mode
    (tempel-insert (eglot-tempel--convert snippet))))

;;;###autoload
(defun eglot-tempel--snippet-expansion-fn ()
  "An override of ‘eglot--snippet-expansion-fn’."
  #'eglot-tempel-expand-yas-snippet)

;;;###autoload
(define-minor-mode eglot-tempel-mode
  "Toggle eglot template support by tempel."
  :init-value nil
  :global t
  :lighter nil
  (progn
  (if eglot-tempel-mode
      (unless (advice-member-p 'eglot--snippet-expansion-fn
			       #'eglot-tempel--snippet-expansion-fn)
	(advice-add 'eglot--snippet-expansion-fn
		    :override #'eglot-tempel--snippet-expansion-fn))
    (advice-remove 'eglot--snippet-expansion-fn
		   #'eglot-tempel--snippet-expansion-fn))
  (when (eglot-current-server)
    (eglot-reconnect (eglot-current-server)))))

(provide 'eglot-tempel)
;;; eglot-tempel.el ends here
