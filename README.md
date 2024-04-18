# TellerProject

** Introduction **

This is my implementation of what is described in https://test.teller.engineering/, part of the process of applying to a job at Teller.

Teller has changed their application process since then.

## Implementation comments

In order to simulate an environment close to what Teller works with, I have implemented two servers: 
1 . The API of a generic app that integrates Teller and so is able to use its features (app `:GenericAppBackend`)
2. The API of an example bank (Bank1) to which the generic app is able to make requests (app `:Bank1API`)

Each server has its own and independent authentication module and procedure. Both modules run on the same localhost server, but a router forwards calls to seemingly separate the API's. Also, all the communication that the GenericApp makes with the bank is done through HTTP requests, to simulate a real environment where we don't have direct access to external bank APIs.

In order to make this a lightweight and easy to deploy project, I have not used any database, so there is no requirement to download any specific software. Instead, all the data from the simulation is stored in a Key-Value store in memory (app `:KV`). As soon as the server dies, all data is lost and a new run will start a new clean DB slate.

## How to run the simulation

Once we have downloaded the project and `mix` has set the dependencies with `mix deps.get` at the root of the project, we can run `iex -S mix run` to start the server. Note that in some window computers it may be required to run `iex.bat` instead of `iex`. With the simulation running, the app has started a local server in the designated port from the config file (8080 normally).

In order to interact with any of the servers, either the GenericApp or the Bank1, we have to perform HTTP requests to http://localhost:8080/. In my testing, I have used Postman to make these calls. The parser I have implemented understands JSON encoded bodies (i.e. Content-type = application/json). For a full list of the available endpoints, visit the Router.ex file in `apps\generic_app_backend\lib\generic_app_backend` and `apps\bank_1_api\lib\bank_1_api`. ALL paths that START with /bank1/ are processed by the bank1 API, and all the rest by the generic app.

To interact with either API one has to have a profile in their domain. Each API has an endpoint to create a profile:
- PUT `/new_user` : creates a user in the GenericApp. Requires "first_name", "last_name" and "password" in the body json of the request.
- PUT `/bank1/create_account` : similar as above but for the bank. Apart from a "user profile", creates a bank account and returns the account number.

These requests, plus the login requests, provide access tokens to access the rest of the resources. The Bank1 API has a 2-step authorisation, so we simulate providing an intermediate token with which we can only perform the second step of the verification. BOTH APIS have the same system of identifying users with their username, created by concatenating first_name and last_name with an underscore between.

If sending requests directly to an API, we need to include the access token of that API in the header (["Authorisation": "Bearer TOKEN]). If sending an indirect request to the bank through the GenericApp (all paths with bank1 in their name but not at the start), the app will automatically include any tokens that have been previously issued and captured, but we can override this behaviour by providing a "token" in the body json. 

In both platforms, I have automatically created a user with username "test_user" and password "test", to facilitate the simulation. This user does not have an opened bank account in Bank1 yet, but can create a new one by calling `/bank1/create_account`. The permissions are not perfect and this is just an approximation, such as the `/bank1/create_account` endpoint that is used for both creating a user if it doesn't exits and an account. For this reason, it does not require two-step verification unlike the rest of the Bank1 endpoints. There are many individual parts of this project that can be perfected. Most of the security can be steped up by providing better secrets to the encoders and storing the sensitive information more carefully.

Here I give a full list of the endpoints.

## GenericAppBackend Endpoints

- GET `/` : health check. Should return `status: 200, "GenericApp: OK"`
- PUT `/new_user` : creates a user in the GenericApp. Requires "first_name", "last_name" and "password" in the body json of the request. Returns a bearer token that should be put in all requests for authorisation purposes of the GenericApp backend.
- POST `/login` : Requires "username" and "password" in body. Returns a bearer token that should be put in all requests for authorisation purposes of the GenericApp backend.
- GET `/users/:username` : Gets user detail from GenericApp
- GET `/accounts/:bank_name` : Gets user accounts in bank "bank_name" (only "bank1" is implemented
- PUT `/transactions/:bank_name` : Gets all transactions from account provided in `account_id` of body.
- PUT `/enroll/:bank_name` : enrolls GenericApp account in bank_name. This endpoint authenticates the user with the required information by the bank. In our case, bank1 requires "username" and "password", and redirects us to another page, where we have to answer which is our favourite colour (security question).
- PUT `/enroll/bank1/step2` : personalized endpoint for the second step of enrolling in bank1. Once our user has succesfully passed the first step of the bank1 auth, we send a request on his behalf to complete the process, once he has given us his "secret_answer". This endpoit requires the "secret_answer" in the body json, and the Bearer token produced in the first step of enrolment.

## Bank1API endpoints

- GET `/bank1/` : health check. Should return `status: 200, "Bank1: OK"`
- PUT `/bank1/create_account` : Creates a bank account and bank profile too if necessary. Each user is restricted to 3 bank accounts. Requires "first_name", "last_name" and "password" in the body json of the request. Returns a bearer token that can be put in all requests for authorisation purposes of the Bank1 backend.
- POST `/bank1/login` : First step in 2-step auth process. Requires "username" and "password". Returns token that authorizes the next step at `bank1/security`
- PUT `/bank1/security` : Endpoint to input the answer to the security question. By default all users have "orange" as an answer. If the answer is right, this endpoint provides a bearer token that authorizes all other endpoints.
- PUT `/bank1/transactions` : Lists all transactions from the account "account_id" in the request body. If instead the body also includes the information "beneficiary_name" and "amount" (in number format, without quotes), this endpoint CREATES a new transaction.
- GET `/bank1/:username/accounts` : Gets all accounts from user.



Let me know if you have any trouble setting this up and I hope it is straightforward to understand. My email is jorgeegallegofeliciano@gmail.com.


