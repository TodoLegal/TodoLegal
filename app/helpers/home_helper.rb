module HomeHelper
  def get_google_drive_search_back_link_path
    # TODO: Remove this
    if @folder && @folder!=""
      return google_drive_search_path + "?get_parent_files=true&folder=" + @folder
    elsif @query && @query!=""
      return google_drive_search_path
    end
    return back_link_path = "/"
  end
  def get_google_drive_covid_search_back_link_path
    if @folder && @folder!=""
      return google_drive_covid_search_path + "?get_parent_files=true&folder=" + @folder
    elsif @query && @query!=""
      return google_drive_covid_search_path
    end
    return back_link_path = "/"
  end
end
