# DROP TABLE IF EXISTS UserLikeRecipe;
# DROP TABLE IF EXISTS UserRatesRecipe;
# DROP TABLE IF EXISTS RecipeIncludesIngredients;
# DROP TABLE IF EXISTS MarketsSellsIngredients;
#
# DROP TABLE IF EXISTS Nutrition;
# DROP TABLE IF EXISTS Recipes;
# DROP TABLE IF EXISTS Users;
# DROP TABLE IF EXISTS Ingredients;
# DROP TABLE IF EXISTS Markets;


CREATE TABLE Users (
    user_id         INT NOT NULL,
    user_email      VARCHAR(50) NOT NULL UNIQUE,
    user_name       VARCHAR(20) NOT NULL,
    password        VARCHAR(100) NOT NULL,

    PRIMARY KEY (user_id)
);

CREATE TABLE Recipes (
    recipe_id       INT NOT NULL AUTO_INCREMENT,
    recipe_name     VARCHAR(255) NOT NULL,
    recipe_type     VARCHAR(10),
    user_email      VARCHAR(50) NOT NULL,

    PRIMARY KEY (recipe_id),
    FOREIGN KEY (user_email) REFERENCES Users(user_email) ON DELETE CASCADE
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
    fat             DECIMAL(5, 2),

    PRIMARY KEY (recipe_id),
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id) ON DELETE CASCADE
);

CREATE TABLE Markets (
    market_id           INT NOT NULL,
    market_name         VARCHAR(30) NOT NULL,
    market_location     VARCHAR(50) NOT NULL,

    PRIMARY KEY (market_id)
);

#---------------- many-to-many tables ----------------#
CREATE TABLE UserLikeRecipe (
    user_id         INT NOT NULL,
    recipe_id       INT NOT NULL,

    PRIMARY KEY (user_id, recipe_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id)
);

CREATE TABLE UserRatesRecipe (
     user_id        INT NOT NULL,
     recipe_id      INT NOT NULL,
     rating         INT NOT NULL,
     comment        VARCHAR(200),

     PRIMARY KEY (user_id, recipe_id),
     FOREIGN KEY (user_id) REFERENCES Users(user_id),
     FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id)
);

CREATE TABLE RecipeIncludesIngredients (
    recipe_id           INT NOT NULL,
    ingredient_id       INT NOT NULL,

    PRIMARY KEY (recipe_id, ingredient_id),
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES Ingredients(ingredient_id) ON DELETE CASCADE
);

CREATE TABLE MarketsSellsIngredients (
    market_id           INT NOT NULL,
    ingredient_id       INT NOT NULL,

    PRIMARY KEY (market_id, ingredient_id),
    FOREIGN KEY (market_id) REFERENCES Markets(market_id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES Ingredients(ingredient_id) ON DELETE CASCADE
);
