;;; lisp/named-vterm.el -*- lexical-binding: t; -*-

(provide 'named-vterm)

(defcustom named-vterm-display-positions
  '((bottom . (display-buffer-in-side-window . ((side . bottom) (window-height . 0.25) (slot . 0))))
    (left . (display-buffer-in-side-window . ((side . left) (window-width . 0.5) (slot . 0))))
    (right . (display-buffer-in-side-window . ((side . right) (window-width . 0.5) (slot . 0))))
    (here . (display-buffer-same-window)))
  "Mapping of position names to display buffer actions for vterm terminals.
Each entry is (POSITION-NAME . ACTION) where ACTION is passed to `pop-to-buffer`."
  :type '(alist :key-type symbol :value-type sexp)
  :group 'vterm)

(defcustom named-vterm-default-position 'bottom
  "Default position for new vterm terminals."
  :type 'symbol
  :group 'vterm)

;; Auto-kill vterm buffers when shell exits
(add-hook 'vterm-exit-functions
          (lambda (buffer event)
            (when (buffer-live-p buffer)
              (kill-buffer buffer))))

;; Switch To / Open Terminal
;; The +vterm/here +vterm/toggle commands fail to "upsert" a terminal buffer
;; Ie., Switch to the terminal buffer if it exists, and if it doesn't create one and switch
;; They also fail to allow more than one vterm terminal to exist and be easily switched to.
(defun named-vterm-format-buffer-id-context ()
  "Return name of current context for vterm terminals.
The context is either the project name, or if not in a project the current directory."
  (if (project-current)
      (project-name (project-current))
    default-directory))

(defun named-vterm-format-buffer-id (&optional name)
    "Returns an ID for a vterm buffer unique to the current context.
The current context is either the project or the current directory (if not in a project).
NAME is an optional user facing identifier for the buffer used to distinguish multiple vterm buffers from each other in the same context.
The ID of a vterm buffer should uniquely identify it across all other vterm buffers.
"
  (concat
     "*vterm:"
     (named-vterm-format-buffer-id-context)
     (if name (concat ":" name) "")
     "*"))

(defun vterm-buffer-list (&optional buffers)
   "List all vterm buffers.
If BUFFERS is provided filters that list. If not provided uses (buffer-list)"
   (seq-remove (lambda (buf) (with-current-buffer buf (not (eq major-mode 'vterm-mode)))) (or buffers (buffer-list))))

(defvar named-vterm-buffer-metadata--local-var-context '+named-vterm--context
  "The buffer local value used to store a vterm buffer's context.")

(defvar named-vterm-buffer-metadata--local-var-name '+named-vterm--name
  "The buffer local value used to store a vterm buffer's name.")

(defvar named-vterm-buffer-metadata--local-var-id '+named-vterm--id
  "The buffer local value used to store a vterm buffer's id.")

(defvar named-vterm-buffer-metadata--local-var-position '+named-vterm--position
  "The buffer local value used to store a vterm buffer's position.")

(defun named-vterm-get-buffer-metadata-plist (buffer)
  "Get plist with metadata about BUFFER

The returned plist will have the keys

  :context  Name of project or directory if not in project (See
            `named-vterm-format-buffer-id-context')
  :name     The user provided name to identify the buffer
  :id      Unique identifier for vterm buffer across all other vterm buffers
"
  `(:context ,(if (buffer-local-boundp named-vterm-buffer-metadata--local-var-context buffer)
                  (buffer-local-value named-vterm-buffer-metadata--local-var-context buffer))
    :name    ,(if (buffer-local-boundp named-vterm-buffer-metadata--local-var-name buffer)
                  (buffer-local-value named-vterm-buffer-metadata--local-var-name buffer))
    :id      ,(if (buffer-local-boundp named-vterm-buffer-metadata--local-var-id buffer)
                  (buffer-local-value named-vterm-buffer-metadata--local-var-id buffer))
    :position ,(if (buffer-local-boundp named-vterm-buffer-metadata--local-var-position buffer)
                  (buffer-local-value named-vterm-buffer-metadata--local-var-position buffer))))

(defun named-vterm-set-buffer-metadata (metadata &optional buffer)
  "Sets METADATA for BUFFER.

METADATA should be a plist in the format returned by `named-vterm-get-buffer-metadata-plist'.
If BUFFER is not set then `current-buffer' is used."
  (let ((context (plist-get metadata :context))
        (name (plist-get metadata :name))
        (id (plist-get metadata :id))
        (position (plist-get metadata :position)))
    (with-current-buffer (or buffer (current-buffer))
      (when (plist-member metadata :context)
          (set (make-local-variable named-vterm-buffer-metadata--local-var-context) context))
      (when (plist-member metadata :name)
          (set (make-local-variable named-vterm-buffer-metadata--local-var-name) name))
      (when (plist-member metadata :id)
          (set (make-local-variable named-vterm-buffer-metadata--local-var-id) id))
      (when (plist-member metadata :position)
          (set (make-local-variable named-vterm-buffer-metadata--local-var-position) position)))))

(defun named-vterm-get-display-action (position)
  "Get display action for POSITION from `named-vterm-display-positions`."
  (or (cdr (assoc position named-vterm-display-positions))
      (cdr (assoc named-vterm-default-position named-vterm-display-positions))
      '(display-buffer-at-bottom . ((window-height . 0.25)))))

(defun named-vterm-get-buffer-by-id (id)
  "Find a vterm buffer by its id
ID is a unique identifier for the buffer (See `named-vterm-format-buffer-id')."
  (car (seq-remove
          (lambda (buf) (not (string-equal (plist-get (named-vterm-get-buffer-metadata-plist buf) :id) id)))
          (vterm-buffer-list))))

(defun named-vterm-get-buffer-list-for-context (ctx &optional buffers)
  "List all vterm buffers for a CTX.
CTX is either the project name or current directory if not in a project (See `named-vterm-format-buffer-id-context').
BUFFERS is the list of buffers to filter, if not provided `vterm-buffer-list''s default BUFFERS value is used."
  (seq-remove
   (lambda (buf) (not (string-equal (plist-get (named-vterm-get-buffer-metadata-plist buf) :context) ctx)))
   (vterm-buffer-list buffers)))

(defun named-vterm-get-display-name (name)
  "Get display name for terminal, converting nil to 'main'."
  (or name "main"))

(defun named-vterm-normalize-name (name)
  "Normalize terminal name, converting 'main' to nil."
  (if (string-equal name "main") nil name))

(defun named-vterm-get-buffer-user-provided-name-list-for-context (ctx)
  "For a CTX list all user provided names for vterm buffers."
  (mapcar (lambda (buf) (plist-get (named-vterm-get-buffer-metadata-plist buf) :name)) (named-vterm-get-buffer-list-for-context ctx)))

(defun named-vterm-open-or-create (name &optional position)
  "Opens or creates a new vterm buffer with NAME.

Sets buffer metadata as described by `named-vterm-set-buffer-metadata'"
  (let* ((id (named-vterm-format-buffer-id name))
         (existing-buff (named-vterm-get-buffer-by-id id))
         (buffer (or existing-buff
                     (let ((new-buffer (get-buffer-create id)))
                       (with-current-buffer new-buffer
                         (unless (eq major-mode 'vterm-mode)
                           (vterm-mode))
                         (named-vterm-set-buffer-metadata
                          `(:context ,(named-vterm-format-buffer-id-context)
                            :name ,name
                            :id ,id
                            :position ,(or position named-vterm-default-position))))
                       new-buffer)))
         (buff-name (named-vterm-get-display-name
                     (plist-get (named-vterm-get-buffer-metadata-plist buffer) :name))))
    (if existing-buff
        (message (format "Switching to terminal %s" buff-name))
      (message (format "Creating terminal %s" buff-name)))
    (let* ((meta (named-vterm-get-buffer-metadata-plist buffer))
           (current-position (plist-get meta :position))
           (target-position (or position current-position named-vterm-default-position))
           (display-buffer-alist nil))  ; Temporarily disable Doom's rules
      
      ;; If position is specified and different from current, move the buffer
      (when (and position current-position (not (eq position current-position)))
        (let ((current-window (get-buffer-window buffer)))
          (when current-window
            (delete-window current-window))))
      
      ;; Update position metadata if provided
      (when position
        (named-vterm-set-buffer-metadata `(:position ,position) buffer))
      
      (pop-to-buffer buffer (named-vterm-get-display-action target-position)))))

(defun named-vterm-visible-buffer-list-for-context (ctx)
  "Get list of vterm buffers which are visible to the user right now.
CTX is the context for which to get buffers (either project name or current directory if not in project)."
  (named-vterm-get-buffer-list-for-context
   ctx
   (vterm-buffer-list (mapcar
                       (lambda (window) (window-buffer window))
                       (window-list)))))

(defun named-vterm--read-position ()
  "Prompt user to select a position from `named-vterm-display-positions`."
  (intern (completing-read "Position: "
                          (mapcar #'car named-vterm-display-positions)
                          nil t)))

(defun named-vterm--read-name ()
  "Prompt user to select a terminal name."
  (let ((input (completing-read
                "Terminal name: "
                (mapcar #'named-vterm-get-display-name (named-vterm-get-buffer-user-provided-name-list-for-context (named-vterm-format-buffer-id-context))))))
    (named-vterm-normalize-name input)))

(defun named-vterm/cycle-next-buffer (&optional position)
  "Cycle to the next vterm buffer for the project or create one if none.

If the current vterm isn't focused then focus that instead.
With PREFIX ARGUMENT, also prompt for position."
  (interactive (list (when current-prefix-arg (named-vterm--read-position))))
  (let* ((first-visible-vterm-buff (car (named-vterm-visible-buffer-list-for-context (named-vterm-format-buffer-id-context))))
         (vterm-buffs (sort (named-vterm-get-buffer-list-for-context (named-vterm-format-buffer-id-context))))
         (next-vterm-buff (or
                           (car (cdr (member first-visible-vterm-buff vterm-buffs))) ;; Get next vterm buffer
                           (car vterm-buffs)))) ;; If first-visible-vterm-buff was last item then wrap around and get first

    (if (and first-visible-vterm-buff (not (eq first-visible-vterm-buff (current-buffer))))
        ;; Focus first-visible-vterm-buff if it isn't focused
        (named-vterm-open-or-create (plist-get (named-vterm-get-buffer-metadata-plist first-visible-vterm-buff) :name) position)

      ;; Cycle to next terminal if first-visible-vterm-buff is focused
      (if next-vterm-buff
          (if (not (eq (current-buffer) next-vterm-buff))
              (named-vterm-open-or-create (plist-get (named-vterm-get-buffer-metadata-plist next-vterm-buff) :name) position)
            (message "Only one terminal"))
        (named-vterm-open-or-create nil position)))))

(defun named-vterm/switch-to-name (name &optional position)
  "Switch to a vterm buffer by selecting a name.

NAME can either be a named vterm or nil to indicate the main terminal.
With PREFIX ARGUMENT, also prompt for position (asked first)."
  (interactive
   (let* ((pos (when current-prefix-arg (named-vterm--read-position)))
          (name (named-vterm--read-name)))
     (list name pos)))
  (named-vterm-open-or-create name position))

(defun named-vterm/rename (name)
  "Rename the currently focused vterm buffer."
  (interactive (let* ((meta (named-vterm-get-buffer-metadata-plist (current-buffer)))
                      (meta-id (plist-get meta :id)))
                 (if (not meta-id) (list nil)
                   (list (read-string "New name: ")))))
  (let* ((normalized-name (named-vterm-normalize-name name))
         (meta (named-vterm-get-buffer-metadata-plist (current-buffer)))
         (meta-id (plist-get meta :id))
         (meta-name (plist-get meta :name)))
    (if (not meta-id)
      (message "Not in a named-vterm buffer")
      (named-vterm-set-buffer-metadata `(
                                         :id ,(named-vterm-format-buffer-id normalized-name)
                                         :name ,normalized-name))
      (rename-buffer (named-vterm-format-buffer-id normalized-name))
      (message (format "Renamed named-vterm '%s' to '%s'" (named-vterm-get-display-name meta-name) (named-vterm-get-display-name normalized-name))))))

(defun named-vterm/set-position (position)
  "Set the display position for the current vterm buffer."
  (interactive 
   (let* ((meta (named-vterm-get-buffer-metadata-plist (current-buffer)))
          (meta-id (plist-get meta :id)))
     (if (not meta-id)
         (list nil)
       (list (named-vterm--read-position)))))
  (when position
    (let* ((meta (named-vterm-get-buffer-metadata-plist (current-buffer)))
           (meta-id (plist-get meta :id))
           (meta-name (plist-get meta :name)))
      (if (not meta-id)
          (message "Not in a named-vterm buffer")
        (named-vterm-open-or-create meta-name position)
        (message "Set vterm position to '%s'" position)))))
