ActiveAdmin.register Place do
  menu parent: "Shop Items", label: "Places"

  permit_params :title, :location, :is_online


  form do |f|
    f.inputs "Place Details" do
      f.input :title
      f.input :location
      f.input :is_online
    end
    f.actions
  end
end
