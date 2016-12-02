(in-package #:cl-neovim)


(defparameter *manual-implementation* '(subscribe unsubscribe call-atomic))

(defparameter *arg-conversions*
  '(("boolean" . (or arg :false))
    ("array"   . (or arg #()))))

(cl:defun parse-parameters (parameters)
  "Extract names from nvim api's metadata of arguments into a list of symbols."
  (mapcar #'(lambda (arg) (vim-name->symbol (second arg))) parameters))

(cl:defun mdata->lisp-function (&key name parameters &allow-other-keys)
  "Create functions from the parsed nvim api (generated by api.lisp)."
  (let* ((parameter-names (append (parse-parameters parameters)))
         (instance-parameter '(&optional (instance *nvim-instance*)))
         (fn-name (vim-name->symbol (clean-up-name name)))
         (async-fn-name (symbol-concat fn-name '/a))
         (funcalls `((,fn-name call/s)
                     (,async-fn-name call/a)))
         (arg-conversions (loop for (type _) in parameters
                                for name in parameter-names
                                when (assoc type *arg-conversions* :test #'string-equal)
                                  collect `(,name ,(subst name 'arg (rest (assoc type *arg-conversions* :test #'string-equal)) :test #'symbol-name=)))))
    (loop for (fn-name fn) in funcalls
          collect (if (setterp name)
                    `(cl:defun (setf ,fn-name) (,@(last parameter-names) ,@(butlast parameter-names) ,@instance-parameter)
                       ,(if arg-conversions
                          `(let (,@arg-conversions)
                             (,fn instance ,name ,@parameter-names))
                          `(,fn instance ,name ,@parameter-names)))
                    `(cl:defun ,fn-name (,@parameter-names ,@instance-parameter)
                       ,(if arg-conversions
                          `(let (,@arg-conversions)
                             (,fn instance ,name ,@parameter-names))
                          `(,fn instance ,name ,@parameter-names)))))))

(cl:defun subscribe (event function &optional (instance *nvim-instance*))
  (mrpc:register-callback instance event function)
  (nvim:call/s instance "vim_subscribe" event))

(cl:defun subscribe/a (event function &optional (instance *nvim-instance*))
  (mrpc:register-callback instance event function)
  (nvim:call/a instance "vim_subscribe" event))

(cl:defun unsubscribe (event &optional (instance *nvim-instance*))
  (nvim:call/s instance "vim_unsubscribe" event)
  (mrpc:remove-callback instance event))

(cl:defun unsubscribe/a (event &optional (instance *nvim-instance*))
  (nvim:call/a instance "vim_unsubscribe" event)
  (mrpc:remove-callback instance event))
