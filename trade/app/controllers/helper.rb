# To change this template, choose Tools | Templates
# and open the template in the editor.


def save_image(image_file)
  if image_file && image_file != ""
    tempfile = image_file[:tempfile]
    filename = Time.now.to_i.to_s+rand(999).to_s+image_file[:filename]
    destination = "public/images/upload/#{filename}"
    FileUtils.mkdir_p "public/images/upload"
    FileUtils::cp(tempfile.path, destination)
    path = File.join(FileUtils::pwd, destination)
  else
    path = File.join(FileUtils::pwd, "public/images/item_pix/placeholder_item.jpg")
  end
  path
end

