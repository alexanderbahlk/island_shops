class CategoryImportJob < ApplicationJob
  queue_as :default

  def perform(xml_file_path)
    Rails.logger.info "Starting category import from #{xml_file_path}"

    begin
      CategoryImporter.import_from_xml(xml_file_path)
      Rails.logger.info "Category import completed successfully"
    rescue => e
      Rails.logger.error "Category import failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end
end
