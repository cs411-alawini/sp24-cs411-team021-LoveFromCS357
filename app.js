var express = require('express');
var bodyParser = require('body-parser');
var mysql = require('mysql2');
var path = require('path');
var session = require('express-session');

var app = express();

// Set up the database connection details
var connection = mysql.createConnection({
    host: '34.70.101.192',
    user: 'sxianyu2',
    password: '88888888',
    database: '411_Smaller'
});

// Connect to the database
connection.connect(function(err) {
    if (err) {
        console.error('error: ' + err.message);
        process.exit(1); // Terminate the application with an error code
    }
    console.log('Connected to the MySQL server.');
});

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Middleware
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(session({
    secret: 'secret',
    resave: false,
    saveUninitialized: false
}));

app.use((req, res, next) => {
    res.locals.loggedin = req.session.loggedin || false;
    res.locals.username = req.session.username || '';
    res.locals.userId = req.session.userId || '';  // Ensure this line exists
    next();
});


// Routes
app.get('/', (req, res) => {
    // Check if user is logged in
    if (req.session.loggedin) {
        res.render('index', { recipes: null, message: 'Welcome back, ' + req.session.username });
    } else {
        res.render('index', { recipes: null, message: '' });
    }
});

app.get('/my-likes', function(req, res) {
    if (!req.session.loggedin || !req.session.userId) {
        res.redirect('/login');
        return;
    }

    const userId = req.session.userId;
    connection.query('CALL GetUserLikedRecipes(?)', [userId], function(err, results) {
        if (err) {
            console.error("Error fetching liked recipes:", err);
            res.render('index', { recipes: null, message: "Error fetching your liked recipes" });
            return;
        }
        
        // results[0] gives you the first result set of multiple result sets from a stored procedure
        const recipes = results[0];

        res.render('index', { recipes, message: "", fromLike: true });
    });
});



app.post('/search-by-recipe', (req, res) => {
    const keywords = req.body.keyword.split(',').map(k => k.trim());
    let query = 'SELECT recipe_id, recipe_name FROM Recipes WHERE';
    const conditions = keywords.map((keyword, index) => {
        return ` recipe_name LIKE ?`;
    }).join(' OR ');

    query += conditions;
    const params = keywords.map(keyword => `%${keyword}%`);

    connection.query(query, params, (err, results) => {
        if (err) {
            console.error(err);
            res.status(500).send('Database error occurred.');
            return;
        }
        res.render('index', { recipes: results, message: '' ,fromLike: false}); // Include message as an empty string
    });
});


app.post('/search-by-ingredient', (req, res) => {
    const ingredients = req.body.ingredient.split(',').map(ingredient => ingredient.trim());
    let query = `
        SELECT DISTINCT Recipes.recipe_id, Recipes.recipe_name 
        FROM Recipes 
        JOIN RecipeIncludesIngredients ON Recipes.recipe_id = RecipeIncludesIngredients.recipe_id
        JOIN Ingredients ON RecipeIncludesIngredients.ingredient_id = Ingredients.ingredient_id
        WHERE`;
    const conditions = ingredients.map(ingredient => {
        return ` Ingredients.ingredient_name LIKE ?`;
    }).join(' OR ');

    query += conditions;
    const params = ingredients.map(ingredient => `%${ingredient}%`);

    connection.query(query, params, (err, results) => {
        if (err) {
            console.error(err);
            res.status(500).send('Database error occurred.');
            return;
        }
        res.render('index', { recipes: results, message: '',fromLike: false});
    });
});



app.post('/login', (req, res) => {
    const { useremail, password } = req.body;

    connection.query('SELECT user_id, user_name FROM Users WHERE user_email = ? AND password = ?', [useremail, password], function(error, results) {
        if (error) {
            console.error('Database error:', error);
            res.render('index', { recipes: null, message: 'Database error during login.' });
            return;
        }

        if (results.length > 0) {
            req.session.loggedin = true;
            req.session.userId = results[0].user_id;  // Storing user_id in the session
            req.session.username = results[0].user_name; // Storing username in the session
            // res.render('index', { recipes: null, message: 'Login successful!', loggedin: true });
            res.redirect('/'); // Redirect to the homepage or a dashboard after successful login
        } else {
            res.render('index', { recipes: null, message: 'Incorrect Username and/or Password!', loggedin: false });
        }
    });
});

app.post('/register', (req, res) => {
    const { useremail, username, password } = req.body;

    connection.query('SELECT user_name FROM Users WHERE user_email = ?', useremail, function(error, results) {
        if (error) {
            console.error('Database error:', error);
            res.render('index', { recipes: null, message: 'Database error during register.' });
            return;
        }

        if (results.length > 0) {
            // User email already exists
            res.render('index', { recipes: null, message: 'Email already exists. Please login or use another email.' });
        } else {
            //Get maximum user id in the data base (INT)
            connection.query('SELECT MAX(user_id) as max_id FROM Users', function(error, result){
                if (error) {
                    console.error('Database error:', error);
                    res.render('index', { recipes: null, message: 'Database error during register.' });
                    return;
                }
                const maxId = result[0].max_id; // || 0; // Handle the case where there are no users
                const newUserId = maxId + 1;

                connection.query('INSERT INTO Users (user_id, user_email, user_name, password) VALUES (?, ?, ?, ?)', 
                [newUserId, useremail, username, password], function(insertError, insertResult) {
                    if (insertError) {
                        console.error('Database error when inserting new user:', insertError);
                        res.render('index', { recipes: null, message: 'Failed to create account. Please try again.' });
                        return;
                    }
                    // Successfully created the user
                    res.render('index', { recipes: null, message: 'Account created successfully! Please log in.' });
                })
            })
        }
    });
});

//transaction code
app.post('/rate-recipe', function(req, res) {
    if (!req.session.loggedin || !req.session.userId) {
        res.render('index', { recipes: null, message: "Please log in to rate recipes" });
        return;
    }

    const userId = req.session.userId;
    const { recipeId, rating, comment } = req.body;

    connection.beginTransaction(function(err) {
        if (err) { 
            console.error("Transaction Error:", err);
            res.render('index', { recipes: null, message: "Transaction error" });
            return;
        }

        const insertRatingSql = "INSERT INTO UserRatesRecipe (user_id, recipe_id, rating, comment) VALUES (?, ?, ?, ?)";
        connection.query(insertRatingSql, [userId, recipeId, rating, comment], function(insertErr, insertResults) {
            if (insertErr) {
                return connection.rollback(function() {
                    console.error("Error inserting rating:", insertErr);
                    res.render('index', { recipes: null, message: "Error processing your rating" });
                });
            }

            const logSql = "INSERT INTO RecipeRateLog (user_id, recipe_id, rating, comment) VALUES (?, ?, ?, ?)";
            connection.query(logSql, [userId, recipeId, rating, comment], function(logErr, logResults) {
                if (logErr) {
                    return connection.rollback(function() {
                        console.error("Error logging rating action:", logErr);
                        res.render('index', { recipes: null, message: "Error logging your rating" });
                    });
                }

                connection.commit(function(commitErr) {
                    if (commitErr) {
                        return connection.rollback(function() {
                            console.error("Error committing transaction:", commitErr);
                            res.render('index', { recipes: null, message: "Transaction failed" });
                        });
                    }
                    console.log("Transaction completed successfully.");
                    res.render('index', { recipes: null, message: "Recipe rated successfully!" });
                });
            });
        });
    });
});





app.post('/like-recipe', function(req, res) {
    if (req.session.loggedin && req.session.userId) {
        const userId = req.session.userId; // Use the userId from the session
        const recipeId = req.body.recipeId;

        // First, check if the like already exists
        const checkSql = "SELECT * FROM UserLikeRecipe WHERE user_id = ? AND recipe_id = ?";
        connection.query(checkSql, [userId, recipeId], function(checkErr, checkResults) {
            if (checkErr) {
                console.error("Error checking existing likes:", checkErr);
                res.render('index', { recipes: null, message: "Error checking likes" });
                return;
            }

            if (checkResults.length > 0) {
                // If the like already exists, don't insert and send a message back
                res.render('index', { recipes: null, message: "You have already liked this recipe" });
            } else {
                // Like does not exist, proceed with insertion
                const insertSql = "INSERT INTO UserLikeRecipe (user_id, recipe_id) VALUES (?, ?)";
                connection.query(insertSql, [userId, recipeId], function(insertErr, insertResult) {
                    if (insertErr) {
                        console.error("Error inserting into UserLikeRecipe:", insertErr);
                        res.render('index', { recipes: null, message: "Error processing your like" });
                    } else {
                        console.log("Successfully inserted like into database");
                        res.render('index', { recipes: null, message: "Recipe liked successfully!" });
                    }
                });
            }
        });
    } else {
        res.render('index', { recipes: null, message: "Please log in to like recipes" });
    }
});



app.post('/dislike-recipe', function(req, res) {
    if (req.session.loggedin && req.session.userId) {
        const userId = req.session.userId; // Use the userId from the session
        const recipeId = req.body.recipeId;

        const sql = "DELETE FROM UserLikeRecipe WHERE user_id = ? AND recipe_id = ?";
        connection.query(sql, [userId, recipeId], function(err, result) {
            if (err) {
                console.error("Error deleting like from UserLikeRecipe:", err);
                res.render('index', { recipes: null, message: "Error processing your dislike" });
            } else {
                console.log("Successfully removed like from database");
                res.render('index', { recipes: null, message: "Remove liked recipe successfully!" });
            }
        });
    } else {
        res.render('index', { recipes: null, message: "Please log in to remove liked recipes" });
    }
});

app.get('/like-logs', function(req, res) {
    if (!req.session.loggedin) {
        res.redirect('/login');
        return;
    }

    // Queries to fetch the like and rate logs separately
    const likeQuery = `
        SELECT RecipeLikeLog.log_id, Users.user_name, Recipes.recipe_name, RecipeLikeLog.liked_on
        FROM RecipeLikeLog
        JOIN Users ON Users.user_id = RecipeLikeLog.user_id
        JOIN Recipes ON Recipes.recipe_id = RecipeLikeLog.recipe_id
        ORDER BY RecipeLikeLog.liked_on DESC`;

    const rateQuery = `
        SELECT RecipeRateLog.log_id, Users.user_name, Recipes.recipe_name, RecipeRateLog.rating, RecipeRateLog.comment, RecipeRateLog.rated_on
        FROM RecipeRateLog
        JOIN Users ON Users.user_id = RecipeRateLog.user_id
        JOIN Recipes ON Recipes.recipe_id = RecipeRateLog.recipe_id
        ORDER BY RecipeRateLog.rated_on DESC`;

    // Execute the like query
    connection.query(likeQuery, function(err, likeResults) {
        if (err) {
            console.error("Error fetching like logs:", err);
            res.render('like-logs', { likeLogs: null, rateLogs: null, message: "Error retrieving like logs." });
            return;
        }

        // Execute the rate query inside the callback of the like query
        connection.query(rateQuery, function(err, rateResults) {
            if (err) {
                console.error("Error fetching rate logs:", err);
                res.render('like-logs', { likeLogs: likeResults, rateLogs: null, message: "Error retrieving rate logs." });
                return;
            }

            // Render the page with both results
            res.render('like-logs', { likeLogs: likeResults, rateLogs: rateResults, message: '' });
        });
    });
});



app.post('/changeUserSetting', function(req, res) {
    const { useremail, username, password } = req.body;

    // Check if the email exists in the database
    connection.query('SELECT user_id FROM Users WHERE user_email = ?', [useremail], function(error, results) {
        if (error) {
            console.error('Database error:', error);
            res.render('index', { recipes: null, message: 'Database error while checking email.' });
            return;
        }

        if (results.length > 0) {
            // If the email exists, update the username and password
            const userId = results[0].user_id;  // Extract user_id
            const updateSql = 'UPDATE Users SET user_name = ?, password = ? WHERE user_id = ?';

            connection.query(updateSql, [username, password, userId], function(updateError) {
                if (updateError) {
                    console.error('Database error when updating user:', updateError);
                    res.render('index', { recipes: null, message: 'Failed to update user information.' });
                    return;
                }
                // Successfully updated the user
                res.render('index', { recipes: null, message: 'User information updated successfully.' });
            });
        } else {
            // Email does not exist in the database
            res.render('index', { recipes: null, message: 'Email does not exist. Please use a valid email.' });
        }
    });
});


// Logout route
app.get('/logout', (req, res) => {
    req.session.destroy(err => {
        if (err) {
            return console.log(err);
        }
        res.redirect('/');
    });
});

// Server setup
var port = process.env.PORT || 80;
app.listen(port, () => {
    console.log(`Server running on port ${port}`);
});
