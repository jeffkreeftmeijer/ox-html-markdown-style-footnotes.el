;;; ox-html-markdown-style-footnotes.el --- Markdown-style footnotes for ox-html.el

;;; Commentary:

;; ox-html-markdown-style-footnotes replaces the ox-html's default
;; footnotes with an HTML ordered list, inspired by footnotes sections
;; of some Markdown implementations.

;;; Code:

(require 'ox-html)

(defgroup org-export-html-markdown-style-footnotes nil
  "Options for org-html-markdown-style-footnotes."
  :tag "Org HTML Markdown-style footnotes"
  :group 'org-export
  :version "24.4"
  :package-version '(Org . "8.0"))

(defcustom org-html-markdown-style-footnotes nil
  "Non-nil means to use Markdown-style footnotes in the exported document."
  :group 'org-export-html-markdown-style-footnotes
  :version "24.4"
  :package-version '(Org . "8.0")
  :type 'boolean)

(defun org-html-markdown-style-footnotes--section (orig-fun info)
  (if org-html-markdown-style-footnotes
      (pcase (org-export-collect-footnote-definitions info)
        (`nil nil)
        (definitions
         (format
          (plist-get info :html-footnotes-section)
          (org-html--translate "Footnotes" info)
          (format
           "<ol>\n%s</ol>\n"
           (mapconcat
            (lambda (definition)
              (pcase definition
                (`(,n ,label ,def)
                 (format
                  "<li id=\"fn.%s\" class=\"footdef\" role=\"doc-footnote\" tabindex=\"-1\">%s %s</li>\n"
                  (or label n)
                  (org-trim (org-export-data def info))
                  (format "<a href=\"#fnr.%s\" role=\"doc-backlink\">↩&#65038;</a>" (or label n))))))
            definitions
            "\n")))))
    (funcall orig-fun info)))

  ;;;###autoload
(defun org-html-markdown-style-footnotes-add ()
  (interactive)
  (advice-add 'org-html-footnote-section
              :around #'org-html-markdown-style-footnotes--section))

(defun org-html-markdown-style-footnotes-remove ()
  (interactive)
  (advice-remove 'org-html-footnote-section
                 #'org-html-markdown-style-footnotes--section))

(provide 'ox-html-markdown-style-footnotes)

;;; ox-html-markdown-style-footnotes.el ends here
