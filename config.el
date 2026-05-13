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

;; Make possible to add files to existing emacs from command line
(require 'server)
(unless (server-running-p) (server-start))

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
(defun lsp-bridge-setup-python-lsp-bridge-symlink ()
  "Create a symlink to the lsp-bridge's python-lsp-bridge helper so it can have the required Python dependencies"
  (let* ((lsp-bridge-el-file (locate-library "lsp-bridge"))
         (lsp-bridge-dir (file-name-directory lsp-bridge-el-file))
         (src-file (file-name-concat lsp-bridge-dir "python-lsp-bridge"))
         (dst-file (file-name-concat (expand-file-name "~/.local/bin") "python-lsp-bridge"))
         (existing-symlink-target (file-symlink-p dst-file)))

    (if (file-exists-p src-file)
        (progn

          ;; Remove symlink if lsp-bridge package changed location
          (if (and existing-symlink-target (not (string-equal src-file existing-symlink-target)))
              (progn (delete-file dst-file)
                     (message "Removed symlink '%s', pointed towards old file ('%s')" dst-file existing-symlink-target)))

          ;; Create symlink if it doesn't exist
          (if (not existing-symlink-target)
              (progn (make-symbolic-link src-file dst-file)
                     (message "Created symlink for python-lsp-bridge file '%s' => '%s'" dst-file src-file)))

          ;; Ensure python-lsp-bridge source file has execute permissions
          (if (not (file-executable-p src-file))
              (progn (set-file-modes src-file (logior (file-modes src-file) #o111))
                     (message "Set executable permissions on python-lsp-bridge source file '%s'" src-file)))
          )
      (message "Could not find the python-lsp-bridge helper script in the package directory at '%s'" src-file))
    ))

(use-package! lsp-bridge
  :init
  (lsp-bridge-setup-python-lsp-bridge-symlink)
  :config
  (global-lsp-bridge-mode)
  (setq lsp-bridge-csharp-lsp-server "csharp-ls")
  
  ;; Register lsp-bridge as the primary lookup handler for all modes
  ;; This creates a priority chain where lsp-bridge is tried first,
  ;; then falls back to xref, dumb-jump, ripgrep, etc.
  (set-lookup-handlers! '*' t
   :definition #'lsp-bridge-find-def
   :references #'lsp-bridge-find-references
   :documentation #'lsp-bridge-popup-documentation))

(use-package! ob-http
  :config (org-babel-do-load-languages
           'org-babel-load-languages
           '((emacs-lisp . t)
             (http . t))))

;; Zoom in and out
(load! "snippets/frame-fns.el")
(load! "snippets/frame-cmds.el")
(load! "snippets/zoom-frm.el")
(map! :leader
      :desc "Zoom in all frames"  "+" #'zoom-all-frames-in
      :desc "Zoom out all frames" "-" #'zoom-all-frames-out)
