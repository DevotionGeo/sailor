local session = require "src.session"
local mail = require "src.mail"
local validation = require "src.validation"
local form = require "src.form"

local test = {}

function test.index(page)
	local stringVariable = 'this variable is being passed from a controller to a view!'
    local anotherVar = 2342 -- this one too! \o/
    
    page:write("Here we are testing basic functionalities, such as LP parsing and V-C communication.")

    page:render('index',{stringVariable = stringVariable,anotherVar = anotherVar})
end

function test.mailer(page)
	local message = "Hello!"
	if page.POST['email'] then
        local sent, err = mail.send_message("<"..page.POST['email']..">","This is the subject!","This is the body!")
        if err then
        	message = err
        else
        	message = "The email was sent!"
        end
    end

    page:render('mailer',{msg = message})
end

function test.models(page)
	--Testing Models
    --[[
		I'm using 'User' model for testing under a mysql db.	
		If you want to check it out, you need to create this table:

		create table user(
			id int primary key auto_increment, 
			username varchar(20), 
			password varchar(20)
		);
    ]]
    local User = sailor.model("user")
    local u = User:new()

    u.username = "maria"
    u.password = "12345678"

    local res,errs = u:validate()
    if not res then
    	page:write("failed test!<br/>")
    else
    	page:write("passed test!<br/>")
    end

    if u:save() then
        page:write("saved! "..u.id.."<br/>")
    end
    
    -- FIND() IS NOT YET ESCAPED, DONT USE IT UNLESS YOU WROTE THE 'WHERE' STRING YOURSELF
    local u2 = User:find("name ='francisco'")

    if u2 then
        page:write(u2.id.." - "..u2.username.."<br/>")
    end

    local users = User:find_all()
    for _, user in pairs(users) do 
        page:write(user.id.." - "..user.username.."<br/>")
    end
      
    u.username = "catarina"
    if u:save() then
        page:write("saved! "..u.id.."<br/>")
    end

    local users = User:find_all()
    for _, user in pairs(users) do 
        page:write(user.id.." - "..user.username.."<br/>")
    end

    page:write("Finding user with id 1:<br/>")
    local some_user = User:find_by_id(1)
    if some_user then
        page:write(some_user.id.." - "..some_user.username.."<br/>")
    end

    page:write("Finding user with id 47:<br/>")
    local some_user = User:find_by_id(47)
    if some_user then
        page:write(some_user.id.." - "..some_user.username.."<br/>")
    else
        page:write("User not found!")
    end
end

function test.validation(page)

	local check = function(val_test, test_string, expected_error) 
						local res,err = val_test(test_string)
						page:write("Validation check on '"..(test_string or 'nil').."': ") 
						if expected_error then page:write ("Expected ") end
						if not res then page:write("Error: value "..(err or '')) else page:write("Check!"..(err or '')) end 
						page:write("<br/>")
					end


	local tests = { validation:new().type("string").len(3,5),
					validation:new().type("number").len(3,5),
					validation:new().not_empty(),
					validation:new().len(2,10),
					validation:new().type("number"),
					validation:new().empty(),
					}

	local test_strings = {  "test string!",
							"hey",
							""
						}

	check(tests[1],test_strings[1],true)
	check(tests[2],test_strings[1],true)
	check(tests[3],test_strings[2])
	check(tests[4],test_strings[2])
	check(tests[5],test_strings[2],true)
	check(tests[6],test_strings[3])
	check(tests[3],test_strings[3],true)
	check(tests[3],test_strings[4],true)
	check(tests[6],test_strings[4])

end

function test.modelval(page)
	local User = sailor.model("user")
    local u = User:new()
    u.username = ""
    u.password = "12345"
    local res,err = u:save()
    page:print(unpack(err))
    u.username = "Lala"
    u.password = "12345"
    local res,err = u:save()
    page:print("<br/>",unpack(err))
    u.username = "Lala"
    u.password = "12345678"
    local res,err = u:save()
    page:print("<br/>",unpack(err or {}))
end

function test.form(page)
	local User = sailor.model("user")
	local u = User:new()
	
	u.username = "test"
	
	if next(page.POST) then
		u:get_post(page.POST)
		page:write(u.username)
	end
   
    page:render('form',{user=u,form = form})
end

function test.redirect(page)
	return page:redirect('test',{hey="blah",hue = 2})
end

function test.include(page)
    page:render('include')
end

function test.error(page)
    page:render('error')
end

function test.newsession(page) 
    session.open(page.r)
    session.save({username = "john lennon"})             
    if session.data then
        for k,v in pairs(session.data) do
            page:write(v)
        end
    end
end

function test.opensession(page) 
    session.open(page.r)
    if session.data then
        for k,v in pairs(session.data) do
            page:write(v)
        end
    end
end

function test.destroysession(page) 
    session.destroy(page.r)
end

function test.login(page)
    local access = require "src.access"
    if access.is_guest() then
        page:print("Logging in...<br/>")
        local _,err = access.login("demo","demo")
        page:print(err or "Logged in.")
    else
        page:print("You are already logged in.")
    end
end


return test
