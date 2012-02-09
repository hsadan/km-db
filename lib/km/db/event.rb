require 'km/db/custom_record'
require 'km/db/belongs_to_user'
require 'km/db/has_properties'

module KM::DB
  class Event < CustomRecord
    include BelongsToUser
    include HasProperties

    set_table_name "events"
    named_scope :before, lambda { |date| { :conditions => ["`t` < ?", date] } }
    named_scope :after,  lambda { |date| { :conditions => ["`t` > ?", date] } }

    named_scope :named, lambda { |name| { :conditions => { :n => KM::DB::Key.get(name) } } }

    named_scope :by_date, :order => '`t` ASC'

    # return value of property
    def prop(name)
      properties.named(name).first.andand.value
    end

    def self.record(hash)
      user_name = hash.delete('_p')
      user ||= User.get(user_name)
      raise UserError.new "User missing for '#{user_name}'" unless user.present?

      stamp = Time.at hash.delete('_t')
      key = Key.get hash.delete('_n')

      transaction do
        connection.execute(sanitize_sql_array([%Q{
          INSERT INTO `#{table_name}` (`t`,`n`,`user_id`) VALUES (?,?,?)
        }, stamp,key,user.id]))

        Property.set(hash, stamp, user, last)
      end
    end
  end
end
