DROP TABLE IF EXISTS UserLikeRecipe;
DROP TABLE IF EXISTS UserRatesRecipe;
DROP TABLE IF EXISTS RecipeIncludesIngredients;
DROP TABLE IF EXISTS MarketsSellsIngredients;

DROP TABLE IF EXISTS Nutrition;
DROP TABLE IF EXISTS Recipes;
DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS Ingredients;
DROP TABLE IF EXISTS Markets;

CREATE TABLE Users (
    user_id         INT NOT NULL,
    user_email      VARCHAR(255) NOT NULL UNIQUE,
    user_name       VARCHAR(255) NOT NULL,
    password        VARCHAR(100) NOT NULL,

    PRIMARY KEY (user_id)
);

CREATE TABLE Recipes (
    recipe_id       INT NOT NULL,
    recipe_name     VARCHAR(255) NOT NULL,
    recipe_type     VARCHAR(255),
    user_email      VARCHAR(255) NOT NULL,

    PRIMARY KEY (recipe_id),
    FOREIGN KEY (user_email) REFERENCES Users(user_email) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Ingredients (
    ingredient_id   INT NOT NULL,
    ingredient_name VARCHAR(255) NOT NULL UNIQUE,
    ingredient_type VARCHAR(255),

    PRIMARY KEY (ingredient_id)
);

CREATE TABLE Nutrition (
    recipe_id       INT NOT NULL,
    calorie         DECIMAL(10, 2),
    carbon_hydrate  INT,
    fat             DECIMAL(10, 2),

    PRIMARY KEY (recipe_id),
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Markets (
    market_id           INT NOT NULL,
    market_name         VARCHAR(255) NOT NULL,
    market_location     VARCHAR(255) NOT NULL,

    PRIMARY KEY (market_id)
);

CREATE TABLE UserLikeRecipe (
  user_id INT NOT NULL,
  recipe_id INT NOT NULL,
  PRIMARY KEY (user_id, recipe_id),
  UNIQUE KEY UC_User_Recipe (user_id, recipe_id),
  KEY recipe_id (recipe_id),
  CONSTRAINT FK_UserLikeRecipe_UserID FOREIGN KEY (user_id) REFERENCES Users (user_id) ON DELETE CASCADE,
  CONSTRAINT FK_UserLikeRecipe_RecipeID FOREIGN KEY (recipe_id) REFERENCES Recipes (recipe_id) ON DELETE CASCADE
);


CREATE TABLE UserRatesRecipe (
    user_id         INT NOT NULL,
    recipe_id       INT NOT NULL,
    rating          INT NOT NULL,
    comment         VARCHAR(255),

    PRIMARY KEY (user_id, recipe_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE RecipeIncludesIngredients (
    recipe_id           INT NOT NULL,
    ingredient_id       INT NOT NULL,

    PRIMARY KEY (recipe_id, ingredient_id),
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES Ingredients(ingredient_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE MarketsSellsIngredients (
    market_id           INT NOT NULL,
    ingredient_id       INT NOT NULL,

    PRIMARY KEY (market_id, ingredient_id),
    FOREIGN KEY (market_id) REFERENCES Markets(market_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES Ingredients(ingredient_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE RecipeLikeLog (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    recipe_id INT NOT NULL,
    liked_on DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id) ON DELETE CASCADE
);

CREATE TABLE RecipeRateLog (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    recipe_id INT NOT NULL,
    rating INT NOT NULL,
    comment VARCHAR(255),
    rated_on DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id) ON DELETE CASCADE
);



CREATE TRIGGER AfterLikeInsert
AFTER INSERT ON UserLikeRecipe
FOR EACH ROW
BEGIN
    INSERT INTO RecipeLikeLog(user_id, recipe_id)
    VALUES (NEW.user_id, NEW.recipe_id);
END;


DELIMITER $$

CREATE PROCEDURE GetUserLikedRecipes(IN user_id_param INT)
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE recipe_id INT;
    DECLARE recipe_name VARCHAR(255);

    -- Cursor to iterate through all liked recipes
    DECLARE recipe_cursor CURSOR FOR
        SELECT Recipes.recipe_id, Recipes.recipe_name
        FROM Recipes
        JOIN UserLikeRecipe ON Recipes.recipe_id = UserLikeRecipe.recipe_id
        WHERE UserLikeRecipe.user_id = user_id_param;

    -- Handler for cursor control
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Temporary table to store results
    CREATE TEMPORARY TABLE IF NOT EXISTS TempLikedRecipes (
        recipe_id INT,
        recipe_name VARCHAR(255)
    );

    -- Open the cursor and start fetching records
    OPEN recipe_cursor;

    get_next_recipe: LOOP
        FETCH recipe_cursor INTO recipe_id, recipe_name;
        IF done THEN
            LEAVE get_next_recipe;
        END IF;

        -- Insert each fetched record into the temporary table
        INSERT INTO TempLikedRecipes (recipe_id, recipe_name) VALUES (recipe_id, recipe_name);
    END LOOP;

    CLOSE recipe_cursor;

    -- Return all rows from the temporary table
    SELECT * FROM TempLikedRecipes;

    -- Drop the temporary table after use
    DROP TEMPORARY TABLE TempLikedRecipes;
END$$

DELIMITER ;
