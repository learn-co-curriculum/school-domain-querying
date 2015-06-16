##Overview
Before you get started, the first thing you should do is read through the README. The README tells you that there is a `lib/student.rb` file that is built out and to use it as a guide. Open `lib/student.rb` and read through it, as well as the specs, to get a high level overview of what your end goal is. Now that you have a sense of direction, go ahead and  run the test suite by typing `rspec` into the terminal. As expected, the student class completely passes since it was already created for you. 

The first failing test is in our Course class, `undefined method create_table for Course:Class.` 

If you take a look at `lib/student.rb`, you will see there is a `create_table` method already written. The process for creating a new table will be similar for all of the classes you build, minus a few key details. For exampe, the `SQL` statement for our student class reads `CREATE TABLE IF NOT EXISTS students`. To get this to work for our course class, we will have to change it to `CREATE TABLE IF NOT EXISTS courses`. Don't forget to use commas between your `id`, `name` and `department_id` attributes, otherwise it will be invalid code and your tests will not pass. Compare your Student and Course classes, see the difference? The last thing we need to do is add our reader and writer methods, or `attr_accessors` for `:id`, `:name` and `:department_id`. Our 

###Note: `create_table` and `drop_table` are tested together in the specs, so you will have to build both of them as well as add your `attr_accessors` before your tests pass.

##lib/course.rb

```ruby
class Course
attr_accessor :id, :name, :department_id

  def self.create_table
    sql = <<-SQL
    CREATE TABLE IF NOT EXISTS courses (
      id INTEGER PRIMARY KEY,
      name TEXT,
      department_id INTEGER 
    )
    SQL
     
    DB[:conn].execute(sql)
  end
  
end

```
We now have a way to create a table, but what if we want to drop a table? Yep, we need a `drop_table` method to complete the circuit. Take a look at your `lib/student.rb` and you will see a `drop_table` method for students, use that as your guide. This method is pretty clear, if a table exists, drop it when the method is executed. Just like our `create_table` method, we need to prepend `self`, which accesses our Class scope. By calling `self` on `drop_table`, we will drop all courses in the Course class.

```ruby
def self.drop_table
  sql = "DROP TABLE IF EXISTS courses"
  DB[:conn].execute(sql)
end
```
Run `rspec` and your will see the next error, `undefined method insert`. Again, lets take a look at our `student.rb` file and see if we have reusable code. 

It looks like we have one built for us so lets modify that and use it. Let's also create a helper method called `attribute_values` to keep everything organized. Instead of typing out all of the values in our insert method, we can call the `attribute_values` method instead.

```ruby
def attribute_values
  [name, department_id]
end

def insert
  sql = <<-SQL
    INSERT INTO courses
    (name, department_id)
    VALUES
    (?,?)
  SQL
  DB[:conn].execute(sql, attribute_values)

  @id = DB[:conn].execute("SELECT last_insert_rowid() FROM courses")[0][0]
end
```
Run `rspec`, `undefined method new_from_db`. This method is going to take the information from the database and create a new instance by utilizing a method called tap. Tap "yields self to the block, and then returns self. The primary purpose of this method is to “tap into” a method chain, in order to perform operations on intermediate results within the chain." In our case we are tapping into Course and creating a new instance while assigning it's attributes to specific rows.

```ruby
def self.new_from_db(row)
  self.new.tap do |s|
    s.id = row[0]
    s.name =  row[1]
    s.department_id = row[2]
  end
end
```

Now we can create a Courses table, insert a course and drop a course. I think being able to find a course by it's name would be useful, which is our next error. 

We need to build a method called `find_by_name` Again we can use `lib/student.rb` file as an example, replacing the necessary variables. Here we are selecting all from our Courses table where the name is equal to the param we are passing in, then limiting it to one.

```ruby
 def self.find_by_name(name)
    sql = <<-SQL
      SELECT *
      FROM courses
      WHERE name = ?
      LIMIT 1
    SQL
    result = DB[:conn].execute(sql,name)
    result.map do |row| 
      self.new_from_db(row)
    end.first
  end
```
Let's run `rspec` for our next error, `undefined method find_all_by_department_id`. Here we want to be able to find all courses by their `department_id`. The SELECT statement for this reads pretty clearly, select * (* stands for all) from the Courses table, where the `deparment_id` of the course equals the `id` we are passing in to the method, very simlilar to finding by name. Compare this code with your Student class to see the differences.

```ruby
def self.find_all_by_department_id(id)
  sql = "SELECT * FROM courses WHERE department_id = ?"
  result = DB[:conn].execute(sql,id)
  result.collect do |row| 
    self.new_from_db(row)
  end
end
```
Now we can create a Courses table, insert a course into the table, delete the table, find a course by name or department_id. What if we want to change the title of a course? We need a way to update the table.

Run `rspec` and you will see, `undefined method update`. Let's take a look at our `student.rb` file and see if there is anything to guide us. Looks like there is an `update` method built already, let's deconstruct it.

The `update` method will take the values you are changing, find the object by it's id and update the instance. You can see our helper method `attribute_values` being passed in to the `DB[:conn].execute(sql, attribute_values, id)` part of the method.

```ruby
def update
  sql = <<-SQL
    UPDATE courses
    SET name = ?,department_id = ?
    WHERE id = ?
  SQL
  DB[:conn].execute(sql, attribute_values, id)
end
```
The last piece of this puzzle is the ability to save our changes, which we will write two methods for that work together. 

The first is `persisted?` This is a helper method that checks whether or not the changes exist in the database for the given object. If it did persist, it returns true, if not it returns false. 

In ruby, it is convention that methods ending in a `?` will return either true or false. 

Skip down to the solution and you will notice the double exclamation points in the body of our `persisted?` method. These are called bangs. One bang will negate a boolean. So if something is true, a bang in front will make it false. If it is false, a bang in front will make it true. 

A double bang is a double negation and is commonly used to force a method to return a boolean.

Here is an example:

```ruby
def title
  "I return a string."
end

def title_exists?
  !!title 
end
```
The double bang turns `title` into a boolean so that our `title_exists?` method is useful to us.

In our case `self.id` would return an integer, by calling the double bang it returns a boolean. This way in our save method, we can call `persisted?`, which is a now boolean. 

We are also using the ternary operator which reads like this.

`if_this_is_a_true_value ? then_the_result_is_this : else_it_is_this`

If you put it all together we get the following code which will check if the changes persisted, if they did it will update and save the current object, otherwise `insert` them as a new instance.

```ruby
def persisted?
  !!self.id
end

def save
  persisted? ? update : insert
end
```
##lib/department.rb

For the department class, you will find a lot of the same patterns apply, feel free to use the code you've already written as a guide. With that being said, let's run `rspec` and see what we get. `undefined method 'create_table'` Sounds familiar, let's check out our Course class and see what we can find. 

Looks very similar to our previous `create_table` method, we just have to swap the table name and remove the `department_id` attribute. Since we have to build our `drop_table` method let's do that as well and add our `attr_accessors` while we are at it. So our `lib/department.rb` file will now look like this.

```ruby
class Department
attr_accessor :id, :name

  def self.create_table
    sql = <<-SQL
     CREATE TABLE IF NOT EXISTS departments (
     id INTEGER PRIMARY KEY,
     name TEXT
     )
     SQL

    DB[:conn].execute(sql)
  end

  def self.drop_table
  sql = "DROP TABLE IF EXISTS departments"
    DB[:conn].execute(sql)
  end
   
end
```
*Always remember to use the plural form of the table name in your SQL, departments, not department.*

The next error is looking for an insert method, just like before. Again, reuse your code, swapping out the Courses table variables for Departments.
###`insert`

```ruby
def insert
  sql = <<-SQL
    INSERT INTO departments
    (name)
    VALUES
    (?)
    SQL
  DB[:conn].execute(sql, attribute_values) 
  
  @id = DB[:conn].execute("SELECT last_insert_rowid() FROM departments")[0][0]
end
```

We need another `new_from_db` method, just like before. Make sure the rows we are creating match the attributes of our Departments table, which contains an id and a name.

###`new_from_db`

```ruby
def self.new_from_db(row)
  self.new.tap do |s|
    s.id = row[0]
    s.name =  row[1]
  end
end
```

Next is `find_by_name`, look familar? Again we can resuse our previous code, updating the table we are selecting from, this time it would be Departments.
###`find_by_name`

```ruby
def self.find_by_name(name)
  sql = <<-SQL
    SELECT *
    FROM departments
    WHERE name = ?
    LIMIT 1
  SQL
  result = DB[:conn].execute(sql,name)
  result.map do |row| 
    self.new_from_db(row)
  end.first
end
```

Next we need a `find_by_id` method. This is very similar to `find_by_name`. Here we pass in the id, select all from the departments table where the id is equal to the id we passed in. If there is a match, we create a new instance from the database.

###`find_by_id`
```ruby
def self.find_by_id(id)
  sql = "SELECT * FROM departments WHERE id = ?"
  result = DB[:conn].execute(sql,id)[0] #[]    
  self.new_from_db(result) if result
end
```

Our update and save methods behave exacly the same as they do in our Course class. Again we just have to switch out the tables we are searching to match Departments and make sure we remove the `depatment_id` column.
###`udpate`
```
def update
  sql = <<-SQL
    UPDATE courses
    SET name = ?
    WHERE id = ?
  SQL
  DB[:conn].execute(sql, attribute_values, id)
end
```

###`save`
 ``` 
def persisted?
  !!self.id
end

def save
  persisted? ? update : insert
end
 ```
##lib/registration.rb

Again, we are going to see a very similar pattern as the previous classes. We need `create_table` and `drop_table` methods, as well as `:id`, `:course_id` and `:student_id` attributes. Following our previous code, you should have the following.

```ruby
class Registration
  attr_accessor :id, :course_id, :student_id
  
  def self.create_table
    sql = <<-SQL
    CREATE TABLE IF NOT EXISTS registrations (
      id INTEGER PRIMARY KEY,
      name TEXT
    )
    SQL

    DB[:conn].execute(sql)
  end

  def self.drop_table
    sql = "DROP TABLE IF EXISTS registrations"
    DB[:conn].execute(sql)
  end
  
end
```
Great, registration tests are now all green.

##Integration Tests
In order for the integration tests to pass completely, you will need to build methods that relate Course and Student to Department using joins. They will go in the Course and Student classes.

## Course relation to Department

Since our Courses belong to a Department, they have what is called a foreign key in the form of `department_id`. Since we have access to this, we can call `Department.find_by_id` and pass in the `department_id`. If 
`@department` has not been set yet, it will set it, otherwise it will return `@deparment`. For example, if the Department already exists, it will already have a `department_id` and we would not have to set it again.

```ruby
def department
  @department ||= Department.find_by_id(department_id)
end
```

For our `department=` writer method, we are passing in `department`, then calling `self.department_id`. Here we prepend `self` since we are accessing an instance of the Department class. If we did not use self, we would be writing an overarching Department class. We then set that equal to `department.id`. We have now created a bridge between Course and Department by using our `department_id`.

```ruby 
def department=(department)
  self.department_id = department.id 
end

```

Here we are building a `courses` method that will list out all of the courses in a particular department. From inside our Department class, we are calling `find_by_deparment_id` and passing in `self.id`, which is an instance of a Course accessed by it's `id`.

```ruby 
def courses
  Course.find_all_by_department_id(self.id)
end
```

Here we are building an `add_course` method that does just that, add's a course to a department. In order to do this, we need to tell the computer which department the course belongs to. We do this by calling `course.department_id` and setting it equal to `self.id`, which is the instance of that course based on it's id. We then save it.

```ruby
def add_course(course)
  course.department_id = self.id
  course.save
  self.save
end
```
###Example
```ruby
def add_course(biology) # => Pass in a new course called biology.
  biology.department_id = self.id # => Access that courses department_id, which is in our Course class and set it equal to self.id, which is the instance of a new course in our department that we are creating.
  biology.save # => We then save biology.
  self.save # => And save the new course in our department.
end
```
## Student relation to Department

In our `add_student` method, we are taking in a student, inserting them into our Registrations table using the `course_id` and `student_id`.

```ruby
 def add_student(student)
    sql = "INSERT INTO registrations (course_id, student_id) VALUES (?,?);"
    DB[:conn].execute(sql, self.id, student.id)
  end
```

For our students method, we have a double join, which can be tricky so I've created a visualization below. Read through the code and see if you can figure out what is happening. The takeaway her is how we can join tables together to create a subsection. In our case, we are looking for all students where their student id is present in the registrations and courses tables, therefore showing us who is taking a given course from a specific department.

<img src="join.png">

```ruby
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
```

Our last error is looking for a `students` method, which enables a course to add a student to the instance of that course. Here we have a SQL statement that inserts a given student into our registrations table, using the `course_id` and `student_id`.

```ruby
def add_student(student)
  sql = "INSERT INTO registrations (course_id, student_id) VALUES (?,?);"
  DB[:conn].execute(sql, self.id, student.id)
end
```
Now all of your tests should be passing, hooray!

