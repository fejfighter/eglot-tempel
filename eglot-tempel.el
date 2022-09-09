;;; eglot-tempel.el --- use eglot as inline template expander

;; Copyright (C) 2022 Jeffrey Walsh

;; Author: Jeff Walsh <fejfighter@gmail.com
;; Version: 0.1
;; Package-Requires: (eglot tempel)
;; Keywords: LSP, eglot, template
;; URL: https://github.com/fejfighter/eglot-tempel

;;; Commentary:

;; LSP can provide inline/template hinting for function completion,
;; Currently eglot only checks for yasnippet to enable this
;; feature.  This package patches the function or mocks yasnippet
;; (depending on what is installed) to use tempel.el for that feature
;; by translating the LSP template into a sexp used by tempel.el

(require 'tempel)

;;; Code:
(defun tempel-eglot--convert (snippet)
  "Take a SNIPPET provided by the LSP servier via eglot and return a sexp useful for tempel.el."
  (if (string-match "${\\([1-9]\\):\\([^}]*\\)}" snippet)
      (append `(,(substring snippet 0 (match-beginning 0))
  		,(list 'p (match-string 2 snippet) (match-string 1 snippet)))
  	      (tempel-eglot--convert (substring snippet (match-end 0))))
  `(,snippet q)))

(defun tempel-expand-yas-snippet (snippet &optional START END EXPAND-ENV)
  "Emulate yasnippet expansion function call.
SNIPPET - snippet for converting.
START END EXPAND-ENV are all ignored."
       (tempel-insert (tempel-eglot--convert snippet)))

(if (boundp 'yas-minor-mode)
    (defun eglot--snippet-expansion-fn () 'tempel-expand-yas-snippet)
  (defvar yas-minor-mode t)
  (defun yas-expand-snippet (snippet &optional  START END EXPAND-ENV)
    (tempel-expand-yas-snippet snippet START END EXPAND-ENV)))


(provide 'eglot-tempel)
;;; eglot-tempel.el ends here
