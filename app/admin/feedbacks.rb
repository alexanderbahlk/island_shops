ActiveAdmin.register Feedback do
  menu parent: "Users", label: "Feedback"
  index do
    selectable_column
    id_column
    column :user
    column :content
    column :created_at
    actions
  end

  filter :user
  filter :created_at

  #prevent editing feedbacks
  controller do
    def edit
      redirect_to admin_feedback_path(resource), alert: "Editing feedbacks is not allowed."
    end
  end

  show do
    attributes_table do
      row :id
      row :user
      row :content
      row :created_at
      row :updated_at
    end
  end
end
