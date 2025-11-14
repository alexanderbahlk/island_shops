ActiveAdmin.register Place do
  menu parent: "Shop Items", label: "Places"

  permit_params :title, :location, :is_online

  index do
    selectable_column
    id_column
    column :title
    column :location
    column :is_online
    column :created_at
    column :updated_at
    actions
  end


  form do |f|
    f.inputs "Place Details" do
      f.input :title
      f.input :location
      f.input :is_online
    end
    f.actions
  end
end
