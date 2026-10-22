import axios from "axios";
import express from "express";
import serverless from "serverless-http";
import sharedLib from "shared-lib";

const { greet } = sharedLib;
const app = express();

app.get("/", (_request, response) => {
  response.json({ message: greet("Express Lambda") });
});

app.get("/todo", async (_request, response) => {
  try {
    const apiResponse = await axios.get(
      "https://jsonplaceholder.typicode.com/todos/1",
      { timeout: 5_000 },
    );

    response.status(200).json({
      message: greet("Express Lambda"),
      data: apiResponse.data,
    });
  } catch (error) {
    console.error("Public API request failed:", error.message);
    response.status(502).json({
      message: "Could not retrieve data from the public API",
    });
  }
});

// API Gateway or a Lambda Function URL invokes this; do not call app.listen().
export const handler = serverless(app);
