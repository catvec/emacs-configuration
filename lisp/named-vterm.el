;;; lispq/named-vterm.el -*- lexical-binding: t; -*-
(provide 'named-vterm)

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
                  (buffer-local-value named-vterm-buffer-metadata--local-var-id buffer))))

(defun named-vterm-set-buffer-metadata (metadata &optional buffer)
  "Sets METADATA for BUFFER.

METADATA should be a plist in the format returned by `named-vterm-get-buffer-metadata-plist'.
If BUFFER is not set then `current-buffer' is used."
  (let ((context (plist-get metadata :context))
        (name (plist-get metadata :name))
        (id (plist-get metadata :id)))
    (with-current-buffer (or buffer (current-buffer))
      (if context
          (set (make-local-variable named-vterm-buffer-metadata--local-var-context) context))
      (if name
          (set (make-local-variable named-vterm-buffer-metadata--local-var-name) name))
      (if id
          (set (make-local-variable named-vterm-buffer-metadata--local-var-id) id)))))

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

(defun named-vterm-get-buffer-user-provided-name-list-for-context (ctx)
  "For a CTX list all user provided names for vterm buffers."
  (mapcar (lambda (buf) (plist-get (named-vterm-get-buffer-metadata-plist buf) :name)) (named-vterm-get-buffer-list-for-context ctx)))

(defun named-vterm-open-or-create (name)
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
                            :id ,id)))
                       new-buffer)))
         (buff-name (or
                     (plist-get (named-vterm-get-buffer-metadata-plist buffer) :name)
                     "main")))
    (if existing-buff
        (message (format "Switching to terminal %s" buff-name))
      (message (format "Creating terminal %s" buff-name)))
    (pop-to-buffer buffer)))

(defun named-vterm-visible-buffer-list-for-context (ctx)
  "Get list of vterm buffers which are visible to the user right now.
CTX is the context for which to get buffers (either project name or current directory if not in project)."
  (named-vterm-get-buffer-list-for-context
   ctx
   (vterm-buffer-list (mapcar
                       (lambda (window) (window-buffer window))
                       (window-list)))))

(defun named-vterm-switch-to-id (id)
  "Switch to a vterm buffer with ID and return buffer.
Returns nil if vterm buffer with ID does not exist.
If vterm buffer is closed it will be opened.
If vterm buffer is not focused it will be focused."
  (let ((vterm-buf (named-vterm-get-buffer-by-id id)))
    (if vterm-buf
        (pop-to-buffer vterm-buf))))

(defun named-vterm/open (prefix)
  "Open and focus a vterm buffer.

If a prefix argument is given a vterm buffer name for the vterm to open will be prompted."
  (interactive "P")
  (let ((term-name (if prefix
                       (completing-read
                        "Terminal name: "
                        (named-vterm-get-buffer-user-provided-name-list-for-context (named-vterm-format-buffer-id-context))
                        (lambda (name) name)))))
    (named-vterm-open-or-create term-name)))

(defun named-vterm/cycle-next-buffer ()
  "Cycle to the next vterm buffer for the project or create one if none."
  (interactive)
  (let* ((first-visible-vterm-buff (car (named-vterm-visible-buffer-list-for-context (named-vterm-format-buffer-id-context))))
         (vterm-buffs (sort (named-vterm-get-buffer-list-for-context (named-vterm-format-buffer-id-context))))
         (next-vterm-buff (or
                           (car (cdr (member first-visible-vterm-buff vterm-buffs))) ;; Get next vterm buffer
                           (car vterm-buffs)))) ;; If first-visible-vterm-buff was last item then wrap around and get first
    (if next-vterm-buff
        (if (not (eq (current-buffer) next-vterm-buff))
            (named-vterm-open-or-create (plist-get (named-vterm-get-buffer-metadata-plist next-vterm-buff) :name))
          (message "Only one terminal"))
      (named-vterm/open nil))))

(defun named-vterm/switch-to-name (name)
  "Switch to a vterm buffer by selecting a name.

NAME can either be a named vterm or nil to indicate the main terminal."
  (interactive
   (list
    (let ((input (completing-read
                  "Terminal name: "
                  (mapcar (lambda (name) (or name "main")) (named-vterm-get-buffer-user-provided-name-list-for-context (named-vterm-format-buffer-id-context))))))
      (if (string-equal input "main")
          nil
        input))))
  (named-vterm-open-or-create name))
