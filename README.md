
# ox-html-markdown-style-footnotes: Markdown-style footnotes for ox-html.el

Ox-html-markdown-style footnotes is an Emacs extension that provides an option to export Org mode files to HTML with footnotes that resemble those typical in documents generated from Markdown files.


## Overview

```org
Hello, world![fn:1]

[fn:1] A footnote.

With a second paragraph.
```

The Org document above produces the following footnotes when exported to HTML:

```html
<div id="footnotes">
<h2 class="footnotes">Footnotes: </h2>
<div id="text-footnotes">

<div class="footdef"><sup><a id="fn.1" class="footnum" href="#fnr.1" role="doc-backlink">1</a></sup> <div class="footpara" role="doc-footnote"><p class="footpara">
A footnote.
</p>

<p class="footpara">
With a second paragraph.
</p></div></div>
```

Footnotes consist of a link back to the place the footnote was referenced in the document and a `<div>` with the footnote's contents. The contents div, being a block element, is printed on a seperate line unless the default styling is loaded. The styling makes the footnotes appear inline, which places them behind the footnote link, but also inlines each paragraph for multi-paragraph footnotes:

![img](./before.png "Org's default footnote styling")

Some flavors of Markdown use [ordered lists for footnotes](https://www.markdownguide.org/extended-syntax/#footnotes). These don't rely on styling, and they don't inline paragraphs in the footnotes.

To use Markdown-style footnotes in Org, ox-html-markdown footnotes advises the `org-html-footnote-section` function to overwrite its implementation. This new function keeps most of the output the same, but uses an ordered list instead of nested `<div>` elements. It also uses a backlink with an arrow, which resembles the Markdown tradition:

```html
<div id="footnotes">
<h2 class="footnotes">Footnotes: </h2>
<div id="text-footnotes">
<ol>
<li id="fn.1" class="footdef" role="doc-footnote" tabindex="-1"><p class="footpara">
A footnote.
</p>

<p class="footpara">
With a second paragraph.
</p> <a href="#fnr.1" role="doc-backlink">↩&#65038;</a></li>
</ol>

</div>
</div></div>
```

This results in footnotes with support for multiple paragraphs, that work without additional styling:

![img](./after.png "Footnotes with ox-html-markdown-style-footnotes")


## Implementation

In [Org mode 9.6.5](https://git.savannah.gnu.org/cgit/emacs/org-mode.git/tree/lisp/ox-html.el?h=release_9.6.5#n1858), the `org-html-footnote-section` looks like this:

```emacs-lisp
(defun org-html-footnote-section (info)
  "Format the footnote section.
INFO is a plist used as a communication channel."
  (pcase (org-export-collect-footnote-definitions info)
    (`nil nil)
    (definitions
     (format
      (plist-get info :html-footnotes-section)
      (org-html--translate "Footnotes" info)
      (format
       "\n%s\n"
       (mapconcat
        (lambda (definition)
          (pcase definition
            (`(,n ,_ ,def)
             (let ((inline? (not (org-element-map def org-element-all-elements
                                   #'identity nil t)))
                   (anchor (org-html--anchor
                            (format "fn.%d" n)
                            n
                            (format " class=\"footnum\" href=\"#fnr.%d\" role=\"doc-backlink\"" n)
                            info))
                   (contents (org-trim (org-export-data def info))))
               (format "<div class=\"footdef\">%s %s</div>\n"
                       (format (plist-get info :html-footnote-format) anchor)
                       (format "<div class=\"footpara\" role=\"doc-footnote\">%s</div>"
                               (if (not inline?) contents
                                 (format "<p class=\"footpara\">%s</p>"
                                         contents))))))))
        definitions
        "\n"))))))
```

The function returns nothing if there are no footnotes in the document, or uses the format set in `:html-footnotes-section` to print each footnote. The interesting part is executed for each footnote, and wraps each footnote in a `div` element with a link back to where the footnote is referenced from:

```emacs-lisp
(let ((inline? (not (org-element-map def org-element-all-elements
                      #'identity nil t)))
      (anchor (org-html--anchor
               (format "fn.%d" n)
               n
               (format " class=\"footnum\" href=\"#fnr.%d\" role=\"doc-backlink\"" n)
               info))
      (contents (org-trim (org-export-data def info))))
  (format "<div class=\"footdef\">%s %s</div>\n"
          (format (plist-get info :html-footnote-format) anchor)
          (format "<div class=\"footpara\" role=\"doc-footnote\">%s</div>"
                  (if (not inline?) contents
                    (format "<p class=\"footpara\">%s</p>"
                            contents)))))
```


### Advising `org-html-footnote-section`

To override the footnotes function, first require `ox-html`, the HTML exporter:

```emacs-lisp
(require 'ox-html)
```

Define the `org-html-markdown-style-footnotes` variable, which is used to enable and disable the package after it's included:

```emacs-lisp
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
```

Then, define an updated version of `org-html-footnote-section`, which is mostly a copy of the original. If the `org-html-markdown-style-footnotes` variable is non-nil, the updated copy is used, which is different from the original in multiple ways:

-   It turns the footnote section into an ordered list by wrapping it in `<ol>` tags
-   It switches from a `<div>` element to a list by wrapping each footnote in `<li>` tags
-   It moves the anchor link, which points back at the footnote reference, to the end of the footnote, and uses a Unicode arrow (↩︎) instead of the footnote's number
-   Removes the logic checking if a footnote can be inlined, as it always prints the contents as-is

The updated copy is defined as `org-html-markdown-style-footnotes--section`:

```emacs-lisp
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
                  (`(,n ,_ ,def)
                   (format
                    "<li id=\"fn.%d\" class=\"footdef\" role=\"doc-footnote\" tabindex=\"-1\">%s %s</li>\n"
                  n
                    (org-trim (org-export-data def info))
                    (format "<a href=\"#fnr.%d\" role=\"doc-backlink\">↩&#65038;</a>" n)))))
              definitions
              "\n")))))
    (funcall orig-fun info)))
```

To replace the original, the new function is added as advice. The package includes functions to easily enable and disable itself through adding and removing its advice:

```emacs-lisp
  ;;;###autoload
(defun org-html-markdown-style-footnotes-add ()
  (interactive)
  (advice-add 'org-html-footnote-section
              :around #'org-html-markdown-style-footnotes--section))

(defun org-html-markdown-style-footnotes-remove ()
  (interactive)
  (advice-remove 'org-html-footnote-section
                 #'org-html-markdown-style-footnotes--section))
```

The `:around` [advice strategy](https://www.gnu.org/software/emacs/manual/html_node/elisp/Advice-Combinators.html) is used instead of the more obvious `:override`, because it needs to be possible to disable the override through setting `org-html-markdown-style-footnotes` to `nil`. This isn't possible when using the `:override` strategy, which doesn't call the advice with a reference to the original function.

Finally, the package provides itself as `ox-html-markdown-style-footnotes`:

```emacs-lisp
(provide 'ox-html-markdown-style-footnotes)
```


## Installation and usage

Ox-html-markdown-style-footnotes is currently not available through any of the package registries. Instead, install it from the git repository directly. Install the package with [use-package](https://github.com/jwiegley/use-package), and enable it by calling `org-html-markdown-style-footnotes-add`:

```emacs-lisp
(use-package ox-html-markdown-style-footnotes
  :vc (:url "https://github.com/jeffkreeftmeijer/ox-html-markdown-style-footnotes.el.git")
  :config
  (org-html-markdown-style-footnotes-add))
```

After calling `org-html-markdown-style-footnotes-add`, set the `org-html-markdown-style-footnotes` variable to to enable the package while exporting:

```emacs-lisp
(let ((org-html-markdown-style-footnotes t))
  (org-html-publish-to-html))
```


## Contributing

The git repository for ox-html-markdown-style-footnotes.el is hosted on [Codeberg](https://codeberg.org/jkreeftmeijer/ox-html-markdown-style-footnotes.el), and mirrored on [GitHub](https://github.com/jeffkreeftmeijer/ox-html-markdown-style-footnotes.el). Contributions are welcome via either platform.


### Tests

Regression tests are written with [ERT](https://www.gnu.org/software/emacs/manual/html_mono/ert.html) and included in `test.el`. To run the tests in batch mode, use `scripts/test`, or run the emacs batch command directly:

```shell
emacs -batch -l ert -l test.el -f ert-run-tests-batch-and-exit
```


### Screenshots

The README file for ox-html-markdown-style-footnotes includes screenshots to show what footnotes look like in an HTML page. A script is included to generate these in `scripts/screenshots.js`, which can be run by sourcing it in a shell:

```shell
./scripts/screenshots.js
```

The script loads puppeteer, then launches a headless browser, navigates to `test/fixtures/footnote.html`, takes the screenshot, and closes the browser:

```js
const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();

  await page.setViewport({
    width: 800,
    height: 200,
    deviceScaleFactor: 4
  });

  await page.goto(`file://${__dirname}/../test/fixtures/footnote.html`);
  await page.waitForSelector('body');
  body = await page.$('body');
  await page.evaluate(() => { document.querySelector('body').style.padding = '32px'; });
  await body.screenshot({path: "./before.png"});

  await page.goto(`file://${__dirname}/../test/fixtures/footnote-2.html`);
  await page.waitForSelector('body');
  body = await page.$('body');
  await page.evaluate(() => { document.querySelector('body').style.padding = '32px'; });
  await body.screenshot({path: "./after.png"});

  await page.close();
  await browser.close();
})()
```