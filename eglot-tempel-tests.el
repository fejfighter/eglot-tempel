;;; eglot-tempel-tests.el --- Tests for eglot-tempel.el            -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Jeffrey Walsh

;; Author: Jeff Walsh <fejfighter@gmail.com
;; Keywords: tests

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Tests for eglot-tempel.el

(provide 'tempel)

(require 'eglot-tempel)
(require 'ert)

(ert-deftest test-none ()
  ""
  (should (equal (list "m_noArgs" 'q) (eglot-tempel--convert "m_noArgs"))))

(ert-deftest test-numbered ()
  ""
  (should (equal (list "func(" 'p ")" 'q) (eglot-tempel--convert "func($1)")))
  (should (equal (list "func(" 'p " " 'p ")" 'q) (eglot-tempel--convert "func($1 $2)")))
  (should (equal (list "func(" 'p " " 'p ")" 'q) (eglot-tempel--convert "func(${1} $2)")))
  (should (equal (list "func(" 'p " " 'p ")" 'q) (eglot-tempel--convert "func(${1} ${2})")))
  (should (equal (list "func(" 'p " " 'p " " 'p")" 'q) (eglot-tempel--convert "func($1 $2 $3)"))))

(ert-deftest test-named ()
  ""
  (should (equal (list "func(" (list 'p "named" 1) ")" 'q) (eglot-tempel--convert "func(${1:named})")))
  (should (equal (list "func(" (list 'p "first" 1) " " (list 'p "second" 2 )")" 'q)
		 (eglot-tempel--convert "func(${1:first} ${2:second})")))
  (should (equal (list "func(" (list 'p "_" 1) " " (list 'p "second" 2) ")" 'q)
		       (eglot-tempel--convert "func(${1:} ${2:second})"))))


(ert-deftest test-end ()
  ""
  (should (equal (list "func(" 'p ")" 'q 'q) (eglot-tempel--convert "func($1)$0")))
  (should (equal (list "func(" 'p ")" 'q ";" 'q) (eglot-tempel--convert "func($1)$0;"))))

(ert-deftest test-mixed ()
  ""
  (should (equal (list "func(" (list 'p "named" 1) ")" 'q) (eglot-tempel--convert "func(${1:named})")))
  (should (equal (list "func(" (list 'p "first" 1) " " 'p ")" 'q 'q)
		       (eglot-tempel--convert "func(${1:first} $2)$0"))))

(ert-deftest test-dots ()
  ""
  (should (equal (list "func(" (list 'p "named" 1) " ...)" 'q) (eglot-tempel--convert "func(${1:named} ...)")))
  (should (equal (list "func(" (list 'p "first" 1) " " 'p " ...)" 'q 'q)
		       (eglot-tempel--convert "func(${1:first} $2 ...)$0"))))

(ert-deftest test-choice ()
  ""
  (should (equal (list "func(" (list 'p "one,two,three" 1) ")" 'q)
		 (eglot-tempel--convert "func(${1|one,two,three|})"))))

;;; eglot-tempel-tests.el ends here
