
######### update tags, repeat this script for each tag #############
tag_type = TagType.find_by_name("Tema") # tipo de tag del nuevo tag
@new_tag = Tag.create(name: "Incentivos, Subsidios y Subvenciones", tag_type_id: tag_type.id)
@new_tag = Tag.find_by(name: "Incentivos, Subsidios y Subvenciones") #esto primeto, a veces ya estan creados
@old_tag = Tag.find_by(name: "Incentivos, Indemnizaciones y Subvenciones")

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


################# delete tags ###############

@tag = Tag.find_by(name: "Ratificación de acuerdo")
@documents_with_tag = DocumentTag.where(tag_id: @tag.id )

documents_ids = []
@documents_with_tag.each do | document_tag |
    documents_ids.push(document_tag.document_id)
    document_tag.delete
end

# delete tag from Admin preferences table
UsersPreferencesTag.find_by(tag_id: @tag.id).delete

@tag.delete

#delete from law_tags
@laws_with_old_tag = LawTag.where(tag_id: @old_tag.id)


########## delete tags in users preferences ##############s

@old_tag = Tag.find_by(name: "old tag")
@new_tag = Tag.find_by(name: "new tag")

@all_preferences = UsersPreference.all 

user_ids = []
@all_preferences.each do | preference |
    if preference.user_preference_tags.include?(@old_tag.id)
        user_ids.push(preference.user_id)
        preference.user_preference_tags.delete(@old_tag.id)
        if preference.user_preference_tags.include?(@new_tag.id) == false
            preference.user_preference_tags.push(@new_tag.id)
        end
        preference.save
    end
end

@old_tag.delete