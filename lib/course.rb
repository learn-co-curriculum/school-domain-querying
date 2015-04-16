class Course
  ATTRIBUTES = {
    :id => "INTEGER PRIMARY KEY",
    :name => "TEXT",
    :department_id => "INTEGER"
  }
  attr_accessor *ATTRIBUTES.keys
  attr_reader :department

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
    'courses'
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

  def self.schema_definition
    ATTRIBUTES.collect{|k,v| "#{k} #{v}"}.join(",")
  end

  def self.find_all_by_department_id(id)
    sql = "SELECT * FROM #{table_name} WHERE department_id = ?"
    result = DB[:conn].execute(sql,id)
    result.map do |row| 
      self.new_from_db(row)
    end
  end

  def department
    @department ||= begin
                      Department.find_by_id(department_id)
                    end
  end

  def department=(department)
    self.department_id = department.id
    @department = department
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

  def add_student(student)
    sql = "INSERT INTO registrations (course_id, student_id) VALUES (?,?);"
    DB[:conn].execute(sql, self.id, student.id)
  end

  def students
    sql = <<-SQL
    SELECT students.* 
    FROM students 
    JOIN registrations 
    ON students.id = registrations.student_id 
    JOIN courses 
    ON courses.id = registrations.course_id 
    WHERE students.id = ?
    SQL
    result = DB[:conn].execute(sql, self.id) 
    result.map do |row|
      Student.new_from_db(row)
    end
  end
end