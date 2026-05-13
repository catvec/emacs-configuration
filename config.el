;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;; doom-snazzy
(setq doom-theme 'doom-challenger-deep)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

								; Editor
;; Word Wrap
;; Website: https://docs.doomemacs.org/v21.12/modules/editor/word-wrap/
;; enable word-wrap (almost) everywhere
(+global-word-wrap-mode +1)

;; Language modes
;;(add-to-list 'auto-mode-alist '("\\.sls\\'" . yaml-mode))

                                        ; Term
(load! "snippets/named-vterm.el")

(map! :prefix ("C-c b" . "switch buffers")
      :desc "Open vterm" "T" #'named-vterm/open)
(map! :prefix ("C-c b" . "switch buffers")
      :desc "Cycle vterm" "t" #'named-vterm/cycle-next-buffer)
(map! :prefix ("C-c b" . "switch buffers")
      :desc "Switch to vterm" "n" #'named-vterm/switch-to-name)
(map! :prefix ("C-c b" . "switch buffers")
      :desc "Set vterm position" "p" #'named-vterm/set-position)
(map! :prefix ("C-c b" . "switch buffers")
      :desc "Rename vterm" "r" #'named-vterm/rename)

                                        ; Editor
;; LSP
;; (use-package! lsp-ui
;;   :config
;;   (setq lsp-ui-sideline-show-code-actions 't)
;;   ;; (setq lsp-ui-doc-show-with-mouse 't)
;;   ;; (setq lsp-ui-doc-show-with-cursor 't)
;;   (map! :prefix "C-c b"
;;         :desc "Focus docs popup" "h" #'lsp-ui-doc-focus-frame))
(use-package! lsp-bridge
  :config
  (global-lsp-bridge-mode))

(use-package! ob-http
  :config (org-babel-do-load-languages
           'org-babel-load-languages
           '((emacs-lisp . t)
             (http . t))))

;; Copilot
;; (use-package! copilot
;;   :hook (prog-mode . copilot-mode)
;;   :bind (:map copilot-completion-map
;;               ("<tab>" . 'copilot-accept-completion)
;;               ("TAB" . 'copilot-accept-completion)
;;               ("C-TAB" . 'copilot-accept-completion-by-word)
;;               ("C-<tab>" . 'copilot-accept-completion-by-word)))
;; Zoom in and out
(load! "snippets/frame-fns.el")
(load! "snippets/frame-cmds.el")
(load! "snippets/zoom-frm.el")
(map! :leader
      :desc "Zoom in all frames"  "+" #'zoom-all-frames-in
      :desc "Zoom out all frames" "-" #'zoom-all-frames-out)
