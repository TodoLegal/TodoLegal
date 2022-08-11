
######### update tags, repeat this script for each tag #############
tag_type = TagType.find_by_name("Tema") # tipo de tag del nuevo tag
@new_tag = Tag.create(name: "Tema 3", tag_type_id: tag_type.id)
@old_tag = Tag.find_by(name: "Tema 2")

#save the documents ids
@documents_with_old_tag = DocumentTag.where(tag_id: @old_tag.id )
documents_ids = []

@documents_with_old_tag.each do | document |
    documents_ids.push(document.document_id)
    document.tag_id = @new_tag.id
    document.save
end

# delete tag from Admin preferences table
UsersPreferencesTag.find_by(tag_id: @old_tag.id).delete

@old_tag.delete



################# delete tags ###############

@tag = Tag.find_by(name: "Tema 2")
@documents_with_tag = DocumentTag.where(tag_id: @tag.id )

documents_ids = []
@documents_with_tag.each do | document_tag |
    documents_ids.push(document_tag.document_id)
    document_tag.delete
end

# delete tag from Admin preferences table
UsersPreferencesTag.find_by(tag_id: @old_tag.id).delete

@tag.delete


