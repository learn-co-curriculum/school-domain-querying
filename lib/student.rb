class Student
  attr_accessor :id, :name, :tagline, :github, :twitter, :blog_url, :image_url, :biography

  def self.create_table
    sql = <<-SQL
    CREATE TABLE IF NOT EXISTS students (
      id INTEGER PRIMARY KEY,
      name TEXT,
      tagline TEXT,
      github TEXT,
      twitter TEXT,
      blog_url TEXT,
      image_url TEXT,
      biography TEXT
    )
    SQL

    DB[:conn].execute(sql)
  end

  def self.drop_table
    sql = "DROP TABLE IF EXISTS students"
    DB[:conn].execute(sql)
  end

  def self.new_from_db(row)
    self.new.tap do |s|
      s.id = row[0]
      s.name =  row[1]
      s.tagline = row[2]
      s.github =  row[3]
      s.twitter =  row[4]
      s.blog_url =  row[5]
      s.image_url = row[6]
      s.biography = row[7]
    end
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT *
      FROM students
      WHERE name = ?
      LIMIT 1
    SQL

    DB[:conn].execute(sql,name).map do |row|
      self.new_from_db(row)
    end.first
  end

  def self.find_by_id(id)
    sql = <<-SQL
      SELECT *
      FROM students
      WHERE id = ?
      LIMIT 1
    SQL

    DB[:conn].execute(sql,name).map do |row|
      self.new_from_db(row)
    end.first
  end

  def attribute_values
    [name, tagline, github, twitter, blog_url, image_url, biography]
  end

  def insert
    sql = <<-SQL
      INSERT INTO students
      (name,tagline,github,twitter,blog_url,image_url,biography)
      VALUES
      (?,?,?,?,?,?,?)
    SQL
    DB[:conn].execute(sql, attribute_values)

    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM students")[0][0]
  end

  def update
    sql = <<-SQL
      UPDATE students
      SET name = ?,tagline = ?,github = ?,twitter = ?,blog_url = ?,image_url = ?,biography = ?
      WHERE id = ?
    SQL
    DB[:conn].execute(sql, attribute_values, id)
  end

  def persisted?
    !!self.id
  end

  def save
    persisted? ? update : insert
  end

  def courses
    sql = <<-SQL
    SELECT courses.*
    FROM students
    JOIN registrations
    ON students.id = registrations.student_id
    JOIN courses
    ON courses.id = registrations.course_id
    WHERE students.id = ?
    SQL
    result = DB[:conn].execute(sql, self.id)
    result.map do |row|
      Course.new_from_db(row)
    end
  end

  def add_course(course)
    sql = "INSERT INTO registrations (course_id, student_id) VALUES (?,?);"
    DB[:conn].execute(sql, course.id, self.id)
  end
end
