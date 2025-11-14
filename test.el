(require 'ert)
(load-file "ox-html-markdown-style-footnotes.el")

(ert-deftest footnote-test ()
  (org-html-markdown-style-footnotes-add)
  (find-file "test/fixtures/footnote.org")
  (let ((org-html-markdown-style-footnotes t))
    (org-html-export-as-html))
  (should (string-match-p
           "<ol>\n<li id=\"fn.1\" class=\"footdef\" role=\"doc-footnote\" tabindex=\"-1\"><p class=\"footpara\">\nA footnote.\n</p>\n\n<p class=\"footpara\">\nWith a second paragraph.\n</p> <a href=\"#fnr.1\" role=\"doc-backlink\">↩&#65038;</a></li>\n</ol>"
	   (with-current-buffer "*Org HTML Export*" (buffer-string))))
  (org-html-markdown-style-footnotes-remove))

(ert-deftest labeled-footnote-test ()
  (org-html-markdown-style-footnotes-add)
  (find-file "test/fixtures/labeled-footnote.org")
  (let ((org-html-markdown-style-footnotes t))
    (org-html-export-as-html))
  (should (string-match-p
	   "<ol>\n<li id=\"fn.labeled\" class=\"footdef\" role=\"doc-footnote\" tabindex=\"-1\"><p class=\"footpara\">\nA footnote.\n</p>\n\n<p class=\"footpara\">\nWith a second paragraph.\n</p> <a href=\"#fnr.labeled\" role=\"doc-backlink\">↩&#65038;</a></li>\n</ol>"
	   (with-current-buffer "*Org HTML Export*" (buffer-string))))
  (org-html-markdown-style-footnotes-remove))

(ert-deftest disabled-test ()
  (org-html-markdown-style-footnotes-add)
  (find-file "test/fixtures/footnote.org")
  (let ((org-html-markdown-style-footnotes nil))
    (org-html-export-as-html))

  (let ((buffer (with-current-buffer "*Org HTML Export*" (buffer-string))))
    (should-not (string-match-p "<li class=\"footdef\"" buffer))
    (should (string-match-p "<div class=\"footdef\"" buffer)))

  (org-html-markdown-style-footnotes-remove))
