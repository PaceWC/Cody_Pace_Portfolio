//'create' the initial database
use D597_Task_2


//create the medical collection
db.createCollection("medical")


//create the fitness_trackers collection
db.createCollection("fitness_trackers")


//import the medical data into the medical collection
mongoimport --uri "mongodb://localhost:27017" ^
  --db D597_Task_2 ^
  --collection medical ^
  --file "C:\Users\PaceW\Desktop\WGU\Courses\D597 - Data Management\Task2\Task 2 Scenario 1\Task 2 Scenario 1\medical.json" ^
  --jsonArray


//import the fitness_trackers data into the fitness_trackers collection
mongoimport --uri "mongodb://localhost:27017" ^
  --db D597_Task_2 ^
  --collection fitness_trackers ^
  --file "C:\Users\PaceW\Desktop\WGU\Courses\D597 - Data Management\Task2\Task 2 Scenario 1\Task 2 Scenario 1\Task2Scenario1 Dataset 1_fitness_trackers.json" ^
  --jsonArray


//query 1 what is the medical condition of patients with trackers?
db.medical.aggregate([
  {
    $unwind: "$medical_conditions"  //deconstruct the array to process each condition separately
  },
  {
    $group: {
      _id: "$medical_conditions",   //group by each condition
      count: { $sum: 1 }            
    }
  },
  {
    $sort: { count: -1 }            //sort by most common conditions
  }
]);

//query 1 optimized
db.medical.aggregate([
  { $match: { Tracker: { $exists: true, $ne: null } } },
  { $project: { medical_conditions: 1 } },
  {
    $group: {
      _id: "$medical_conditions",  // group by the full array
      count: { $sum: 1 }
    }
  },
  { $sort: { count: -1 } }
]);


//query 2 identify the most popular and least popular brands
db.fitness_trackers.aggregate([
  { $group: {
      _id: "$Brand Name",       // Group by the 'Brand Name' field
      count: { $sum: 1 }        // Count each occurrence
    }
  },
  { $sort: { count: -1 }        // Sort by count in descending order
  }
])

//query 2 optimized
db.fitness_trackers.aggregate([
  {
    $match: {
      "Brand Name": { $exists: true, $ne: null, $ne: "" }
    }
  },
  {
    $project: {
      brand: "$Brand Name"
    }
  },
  {
    $group: {
      _id: "$brand",
      count: { $sum: 1 }
    }
  },
  {
    $sort: { count: -1 }
  }
]);


//query 3 Do the more expensive models have higher customer reviews?
db.fitness_trackers.aggregate([
  {
    $match: {					//filter out documents with missing, null, or empty selling prices or ratings
      "Selling Price": { $exists: true, $ne: null, $ne: "" },
      "Rating (Out of 5)": { $exists: true, $ne: null, $ne: "" }
    }
  },
  {
    $project: {					//clean and convert string fields to numbers
      brand: "$Brand Name",
      model: "$Model Name",
      cleanedPrice: {			//convert selling price from a string to a double
        $convert: {
          input: {
            $replaceAll: {
              input: "$Selling Price",
              find: ",",
              replacement: ""
            }
          },
          to: "double",
          onError: null,		//error handling
          onNull: null
        }
      },
      rating: {					//convert ratings from string to double
        $convert: {
          input: "$Rating (Out of 5)",
          to: "double",
          onError: null,
          onNull: null
        }
      }
    }
  },
  {
    $match: {				//remove records with invalid values
      cleanedPrice: { $ne: null },
      rating: { $ne: null },
    }
  },
  {
    $group: {				//group by model, compute averages and totals
      _id: { brand: "$brand", model: "$model" },
	  avgRating: { $avg: "$rating" },
      avgSellingPrice: { $avg: "$cleanedPrice" },
      count: { $sum: 1 }
    }
  },
  {
    $project: {				//clean output
      _id: 0,
	  brand: "$_id.brand",
      model: "$_id.model",
      avgSellingPrice: { $round: ["$avgSellingPrice", 2] },
      avgRating: { $round: ["$avgRating", 2] },
      dataPoints: "$count"
    }
  },
  {
    $sort: {				//sort by price (high low), then ratings (high low)
		avgRating: -1,
		avgSellingPrice: -1
		}
  }
]);


//indexes created
db.fitness_trackers.createIndex({ "Brand Name": 1 })

db.fitness_trackers.createIndex({ "Selling Price": 1, "Rating (Out of 5)": 1 })
