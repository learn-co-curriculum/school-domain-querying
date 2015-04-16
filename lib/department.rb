class Department
  ATTRIBUTES = {
    :id => "INTEGER PRIMARY KEY",
    :name => "TEXT",
  }
  attr_accessor *ATTRIBUTES.keys

  def self.create_table
    sql = <<-SQL
      CREATE TABLE IF NOT EXISTS #{table_name} (
    #{schema_definition}
      )
    SQL
    DB[:conn].execute(sql)
  end

  def self.drop_table
    sql = "DROP TABLE IF EXISTS #{table_name}"
    DB[:conn].execute(sql)
  end    

  def self.table_name
    'departments'
  end

  def self.new_from_db(row)
    self.new.tap do |s|
      row.each_with_index do |value, index|
        s.send("#{ATTRIBUTES.keys[index]}=", value)
      end
    end
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{table_name} WHERE name = ?"
    result = DB[:conn].execute(sql,name)[0] #[]    
    self.new_from_db(result) if result
  end

  def self.find_by_id(id)
    sql = "SELECT * FROM #{table_name} WHERE id = ?"
    result = DB[:conn].execute(sql,id)[0] #[]    
    self.new_from_db(result) if result
  end

  def self.schema_definition
    ATTRIBUTES.collect{|k,v| "#{k} #{v}"}.join(",")
  end

  def courses
    Course.find_all_by_department_id(self.id)
  end

  def add_course(course)
    course.department_id = self.id
    course.save
    self.save
  end

  def sql_for_update
    ATTRIBUTES.keys[1..-1].collect{|k| "#{k} = ?"}.join(",")
  end

  def attribute_values
    ATTRIBUTES.keys[1..-1].collect{|key| self.send(key)}
  end

  def insert
    sql = "INSERT INTO #{self.class.table_name} (#{ATTRIBUTES.keys[1..-1].join(",")}) VALUES (#{insert_params})"
    DB[:conn].execute(sql, *attribute_values)

    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.class.table_name}")[0][0]
  end


  def insert_params
    ('?' * (ATTRIBUTES.count - 1)).split("").join(',')
  end

  def update
    sql = "UPDATE #{self.class.table_name} SET #{sql_for_update} WHERE id = ?"
    DB[:conn].execute(sql, *attribute_values, id)
  end    

  def persisted?
    !!self.id
  end

  def save
    persisted? ? update : insert
  end
end