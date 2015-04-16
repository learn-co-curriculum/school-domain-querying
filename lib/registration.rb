class Registration
  ATTRIBUTES = {
    :id => "INTEGER",
    :course_id => "INTEGER",
    :student_id => "INTEGER"
  }
  attr_accessor *ATTRIBUTES.keys

  def self.create_table
    sql = <<-SQL
      CREATE TABLE IF NOT EXISTS registrations (
        #{schema_definition}
      )
    SQL
    DB[:conn].execute(sql)
  end

  def self.drop_table
    sql = "DROP TABLE IF EXISTS registrations"
    DB[:conn].execute(sql)
  end

  def self.schema_definition
    ATTRIBUTES.collect{|k,v| "#{k} #{v}"}.join(",")
  end
end