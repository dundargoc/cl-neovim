(in-package #:cl-neovim)


(cl:defun parse-parameters (parameters)
  "Extract names from nvim api's metadata of arguments into a list of symbols."
  (cond ((listp parameters) (mapcar #'(lambda (arg) (vim-name->symbol (second arg))) parameters))
        ((stringp parameters) (list (vim-name->symbol parameters)))
        (t NIL)))

(defmacro mdata->lisp-function (&key name parameters &allow-other-keys)
  "Create and export functions from the parsed nvim's api."
  (let* ((parameters (parse-parameters parameters))
         (fn-name (vim-name->symbol (clean-up-name name)))
         (sync-fn-name (symbol-concat fn-name '/s))
         (async-fn-name (symbol-concat fn-name '/a))
         (funcalls `((,fn-name #'call/s)
                     (,sync-fn-name #'call/s)
                     (,async-fn-name #'call/a))))
    `(progn ,@(loop for (fn-name fn) in funcalls
                    collect (if (setterp name)
                              `(cl:defun (setf ,fn-name) (,@(last parameters) ,@(butlast parameters))
                                 (funcall ,fn ,name ,@parameters))
                              `(cl:defun ,fn-name ,parameters
                                 (funcall ,fn ,name ,@parameters))))
            ,@(loop for (fn-name _) in funcalls
                    collect `(export ',fn-name :cl-neovim)))))
