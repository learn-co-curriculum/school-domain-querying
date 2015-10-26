# Guide to Solving and Reviewing School Domain Querying

## Overview

 Our goal for this lab is to create an ORM - an Object Relational Mapper. This means we'll be creating a Ruby interface for our database, wrapping SQL statements in methods that perform basic CRUD (Create, Read, Update, Delete) operations. Each of our classes will correspond with a table in our database. We'll be able to create new instances of the classes that align with rows in the database.

We start out with a `lib/student.rb` file that is built out. We'll use this file as a guide to build out similar functionality in our `department` and `course` classes. 

Open `lib/student.rb` and read through it, as well as the specs, to get a high level overview of what your end goal is. Our `course` and `department` models should have similar methods to our `student` class. 

Now that you have a sense of direction, go ahead and  run the test suite by typing `rspec` into the terminal. As expected, the student class completely passes since it was already created for you. 

To begin, we'll define methods to create and drop the corresponding table to our `Course` model. The first failing test is in our Course class, `undefined method create_table for Course:Class.` 

If you take a look at `lib/student.rb`, you will see there is a `create_table` method already written. The process for creating a new table will be similar for all of the classes you build, minus a few key details. For example, the `SQL` statement for our student class reads `CREATE TABLE IF NOT EXISTS students`. To get this to work for our course class, we will have to change it to `CREATE TABLE IF NOT EXISTS courses`. Don't forget to use commas between your `id`, `name` and `department_id` attributes, otherwise it will be invalid code and your tests will not pass. Compare your Student and Course classes, see the difference? The last thing we need to do is add our reader and writer methods, or `attr_accessors` for `:id`, `:name` and `:department_id`. Our 

***Note: `create_table` and `drop_table` are tested together in the specs, so you will have to build both of them as well as add your `attr_accessors` before your tests pass.***

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
We now have a way to create a table, but what if we want to drop a table? Yep, we need a `drop_table` method to complete the circuit. Take a look at your `lib/student.rb` and you will see a `drop_table` method for students, use that as your guide. This method is pretty clear, if a table exists, drop it when the method is executed. Just like our `create_table` method, we need to prepend `self`, which accesses our Class scope. Since the courses table is responsible for storing all the courses in the Course class, it makes sense for this to be a class method.

```ruby
def self.drop_table
  sql = "DROP TABLE IF EXISTS courses"
  DB[:conn].execute(sql)
end
```
Run `rspec` again and the `create_table` and `drop_table` specs should be passing. 

Now that our schema is defined, we can define methods to line up with our CRUD operations. Our goal is to have methods to Create, Read, Update, and Destroy data. Let's start with Create. Our next failing test is , `undefined method insert`. Looking at the spec, we see that our `insert` method needs to insert, or create, a new row in our database. 

 Again, lets take a look at our `student.rb` file and see if we have reusable code. It looks like we have an `insert` method built for us so lets modify that and use it. Our insert method will execute the SQL statement to insert a row into the database based on the name and department id attributes.  

```ruby
def insert
  sql = <<-SQL
    INSERT INTO courses
    (name, department_id)
    VALUES
    (?,?)
  SQL
  DB[:conn].execute(sql, name, department_id)
end
```
Now that we've added a row into the database, we need to tell our course object what ID was created for it. To do this, we'll query the database for the last inserted row, find the ID and assign it to the current instance of course.

```ruby
def insert
  sql = <<-SQL
    INSERT INTO courses
    (name, department_id)
    VALUES
    (?,?)
  SQL
  DB[:conn].execute(sql, name, department_id)

  @id = DB[:conn].execute("SELECT last_insert_rowid() FROM courses")[0][0]
end

```

We've taken care of our `C`, let's move onto our `R`. We want a method to read data out of our database and create a corresponding course object. 

When we run `rspec`, we see `undefined method new_from_db`. Looking at the spec, we see that this method should take an array as an argument representing a row from an argument and return an instance our of course class with the corresponding attributes. 

```ruby
  row = [1, "Advanced .NET Programming"]
  dot_net = Course.new_from_db(row)

  expect(dot_net.id).to eq(row[0])
  expect(dot_net.name).to eq(row[1])
```

We can write this as follows: 

```ruby
def self.new_from_db(row)
  course = self.new
    course.id = row[0]
    course.name =  row[1]
    course.department_id = row[2]
  course
end
```
A shorter way to write this is using the method `tap`.  The `tap` method "yields `self` to the block, and then returns `self`. The primary purpose of this method is to “tap into” a method chain, in order to perform operations on intermediate results within the chain." In our case we are tapping into Course and creating a new instance while assigning it's attributes to specific rows. This allows us to modify the course object we create and return it, instead of having to implicitly return it on a new line. 

```ruby
def self.new_from_db(row)
  self.new.tap do |course|
    course.id = row[0]
    course.name =  row[1]
    course.department_id = row[2]
  end
end
```

Given any row, we can now create a new course object, however, we still don't have a way to query our database for certain rows. It would be nice if we could call a method on our course class, pass it an attribute, such as name, and have it return a ruby object based on what it finds in the database. As in: 

```ruby
course = Course.find_by_name("Advanced Ruby")
#=> #<Course:0x007fa694888b40 @id =1 @name = "Advanced Ruby" @department_id = 1>
```
Let's build out this  `find_by_name` method. Again we can use `lib/student.rb` file as an example, replacing the necessary variables. Here we are selecting all from our courses table where the name is equal to the argument we are passing in, then limiting it to one.

```ruby
 def self.find_by_name(name)
    sql = <<-SQL
      SELECT *
      FROM courses
      WHERE name = ?
      LIMIT 1
    SQL
    result = DB[:conn].execute(sql,name)
  end
```

At this point, use `binding.pry` to see what your result is. It should be a nested array. Each inner array represents one row from the database. Because we limited our results, we should have only one row. 

Now, we can use our `new_from_db` method to create a new instance of our course class. 

```ruby
 def self.find_by_name(name)
    sql = <<-SQL
      SELECT *
      FROM courses
      WHERE name = ?
      LIMIT 1
    SQL
    result = DB[:conn].execute(sql,name)
    self.new_from_db(result.first)
  end
```
Let's run `rspec` for our next error, `undefined method find_all_by_department_id`. This again falls under the "Read" section of our crud actions. Let's take a look at the spec.

```ruby
it "returns records matching a property" do
  dot_net = Course.new
  dot_net.name = "Advanced .NET Programming"
  dot_net.department_id = 9999
  
  dot_net.insert

  dot_net_from_db = Course.find_all_by_department_id(9999)[0]

  expect(dot_net_from_db.name).to eq("Advanced .NET Programming")
  expect(dot_net_from_db).to be_an_instance_of(Course)
end
```
`dot_net_from_db = Course.find_all_by_department_id(9999)` takes an id number as an argument and returns an array of course instances where the department id matches. In this case, we'd get an array of courses which have a department_id of 9999. 

Let's build out the functionality for this method.  The `SELECT` statement for this reads pretty clearly, `SELECT *` (`*` stands for all) from the courses table, where the `department_id` of the course equals the `id` we are passing in to the method, very similar to finding by name. Compare this code with your Student class to see the differences.

```ruby
def self.find_all_by_department_id(id)
  sql = "SELECT * FROM courses WHERE department_id = ?"
  result = DB[:conn].execute(sql,id)
end
```

Again, our result is a nested array, with each array representing a row in our database. Since this method should return an array of Course instances, we can simply call the `collect` method on our result and use our `new_from_db` method to create course instances.

```ruby
def self.find_all_by_department_id(id)
  sql = "SELECT * FROM courses WHERE department_id = ?"
  result = DB[:conn].execute(sql,id)
  result.collect do |row|
    self.new_drom_db(row)
  end
end
```
Now we can create a Courses table, insert a course into the table, delete the table, find a course by name or department_id. What if we want to change the title of a course? Let's move on to the U of our CRUD. We need a way to update the table.

Run `rspec` and you will see `undefined method update`. Let's take a look at our `student.rb` file and see if there is anything to guide us. Looks like there is an `update` method built already, let's deconstruct it.

The `update` method will take the values you are changing, find the object by it's id and update the instance.

```ruby
def update
  sql = <<-SQL
    UPDATE courses
    SET name = ?,department_id = ?
    WHERE id = ?
  SQL
  DB[:conn].execute(sql, name, department_id, id)
end
```

It's kind of annoying that we have to write out each attribute like this. Let's create a helper method called `attribute_values` that will be an array of the attributes for each course instance. We can use this method in our `update` and `insert` methods. 

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


def update
  sql = <<-SQL
    UPDATE courses
    SET name = ?,department_id = ?
    WHERE id = ?
  SQL
  DB[:conn].execute(sql, attribute_values id)
end
```

Now, we have the ability to create or update data in our database. The problem is, to call these methods, we need to know whether our course instance has a corresponding row. For example, using our `update` method on a course that hasn't been saved yet won't work properly. It would be really nice if we could called one method that would update a previously existing row or add a new one. Let's build that method now. We'll call it `save`. 

First, let's build a method to check if an object has been saved to the database. We'll call this method `persisted?`. If the course has a corresponding row, `persisted?` will return `true`, if not it returns `false`. In ruby, it is convention that methods ending in a `?` will return either `true` or `false`. 

How can we tell if a course has been saved to the database? Our courses only get an id value after they've been inserted. This means that any course with an `id` of `nil` only exists in memory. Therefore, our persisted method can check for the presence of an `id`. 

```ruby
def persisted?
  self.id
end
```

This will be truthy if there's any integer value, and falsy if not. We can turn this into an actual `true` or `false` boolean value using exclamation points.  One exclamation will return the opposite boolean. So if something is truthy, an exclamation in front will make it `false`. If it is falsy, an exclamation in front will make it `true`. 

A double exclamation is a double negation and is commonly used to convert something into its boolean equivalent (for example, `!!"hello"` returns `true`, and `!!nil` returns `false`).

Here is an example:

```ruby
def title
  "I return a string."
end

def title_exists?
  !!title 
end
```
The double exclamation turns `title` into a boolean so that our `title_exists?` method returns either `true` or `false`.

In our case `self.id` would return an integer, by calling the double exclamation it returns a boolean. This way in our save method, we can call `persisted?`, which is a now boolean. 

```ruby
def persisted?
  !!self.id
end
```

We can use our `persisted?` method inside of our save method. If `persisted?` returns `true`, we want to run the `update` method. Otherwise, we want to run the `insert` method. We can write this on one line using the ternary operator. 

```ruby
def persisted?
  !!self.id
end

def save
  persisted? ? update : insert
end
```

You've just finished the `course` spec. Give yourself a pat on the back before moving on to the `department`!

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

The next error is looking for an insert method, just like before. Again, reuse your code, swapping out the courses table variables for departments.
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

We need another `new_from_db` method, just like before. Make sure the rows we are creating match the attributes of our departments table, which contains an id and a name.

###`new_from_db`

```ruby
def self.new_from_db(row)
  self.new.tap do |s|
    s.id = row[0]
    s.name =  row[1]
  end
end
```

Next is `find_by_name`, look familar? Again we can resuse our previous code, updating the table we are selecting from, this time it would be departments.
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

Next we need a `find_by_id` method. This is very similar to `find_by_name`. Here we pass in the id and select all from the departments table where the id is equal to the id we passed in. If there is a match, we create a new instance from the database.

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


Since a course belongs to a department, a course needs to have a foreign key, `department_id`. For the `department` method in the Course class, we can call `Department.find_by_id` and pass in the `department_id`. If 
`@department` has not been set yet, it will set it and return it, otherwise it will just return `@deparment`.

###lib/course.rb
```ruby
def department
  @department ||= Department.find_by_id(department_id)
end
```

For `department=`, we  are setting `@department`, if it has already been set, `department` can just return it without having to find it in the database. There are times when `department` is called when `@department` hasn't been set yet, which is why the `||=` is necessary. `||=` reads, set this variable, unless it already has a value.


###lib/course.rb
```ruby 
def department=(department)
  self.department_id = department.id 
end

```

Here we are building a `courses` method that will list out all of the courses in a particular department. From inside our Department class, we are calling `find_by_deparment_id` and passing in `self.id`, which is an instance of a Course accessed by it's `id`.

###lib/department.rb
```ruby 
def courses
  Course.find_all_by_department_id(self.id)
end
```

Here we are building an `add_course` method that does just that, add's a course to a department. In order to do this, we need to tell the computer which department the course belongs to. We do this by calling `course.department_id` and setting it equal to `self.id`, which is the instance of that course based on it's id. We then save it.

###lib/department.rb
```ruby
def add_course(course)
  course.department_id = self.id
  course.save
  self.save
end
```


In our `add_student` method, we are taking in a student, inserting them into our Registrations table using the `course_id` and `student_id`.

###lib/course.rb

```ruby
 def add_student(student)
    sql = "INSERT INTO registrations (course_id, student_id) VALUES (?,?);"
    DB[:conn].execute(sql, self.id, student.id)
  end
```

For our students method, we have a double join, which can be tricky so I've created a visualization below. Read through the code and see if you can figure out what is happening. The takeaway her is how we can join tables together to create a subsection. In our case, we are looking for all students where their student id is present in the registrations and courses tables, therefore showing us who is taking a given course from a specific department.

<img src="join.png">

###lib/course.rb

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

###lib/course.rb
```ruby
def add_student(student)
  sql = "INSERT INTO registrations (course_id, student_id) VALUES (?,?);"
  DB[:conn].execute(sql, self.id, student.id)
end
```
Now all of your tests should be passing, hooray!

