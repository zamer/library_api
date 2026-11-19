# Library Management API

A simple API for managing a library built in Ruby on Rails.

## Run

```bash
docker compose up
```

## Rubocop

```bash
# in docker container
rubocop
```

## Specs

```bash
# in docker container
bundle exec rspec

# test coverage in coverage/index.html
```

## Email previews

```
http://localhost:3000/letter_opener
```

## Usage examples

```bash
# test script with with examples:

sh test.sh
```

## Design choices

1. The book serial and reader card number are generated using the Postgres sequence as a 6 digit number.
2. For testing purposes, reminder emails are not sent. We use the `letter_opener` gem.
3. Loan history - in the `loans` table (book + reader + dates) — gives the full history per book.
4. `due_date` calculated automatically (`borrowed_at + 30 days`) in the model callback.

## Limitations

1. No authorization
2. Emails in dev are view-only

## Possible improvements

1. Endpoints for reader list/management.
2. Loan history per reader.
3. Authorization

## Endpoints

### Create Book

POST /books

Payload:

```json
{
  "book": {
    "title":"Test Book",
    "author":"Author"
  }
}
```

Response:

```json
{
  "serial_number": "000004",
  "title": "Test Book",
  "author": "Author",
  "status": "available",
  "current_loan": null
}
```

### Delete Book

DELETE /books/:serial_number

### Retrieve Book (with history)

GET /books/:serial_number

`the loan history is sortable with the option of pagination.`

Response

```json
{
  "serial_number": "000003",
  "title": "Test Book",
  "author": "Author",
  "status": "available",
  "current_loan": null,
  "loans": [],
  "loans_meta": {
      "current_page": 1,
      "per_page": 20,
      "total_pages": 0,
      "total_count": 0
  }
}
```

### Book list

GET /books

Sorting example: /books?sort=title&order=desc

Pagination example: /books?page=1&per_page=2

Filters example: books?status=borrowed / books?status=available

Response

```json
{
  "data": [
    {
      "serial_number": "000003",
      "title": "Test Book",
      "author": "Author",
      "status": "available",
      "current_loan": null
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total_pages": 1,
    "total_count": 1
  }
}
```

### Borrowing a Book

POST /books/:serial_number/loans

Payload:

```json
{
  "card_number":"000001" # reader card number
}
```

Example response:

```json
{
  "id": 2,
  "borrowed_at": "2026-11-19T09:19:00.123Z",
  "due_at": "2026-12-19T09:19:00.123Z",
  "returned_at": null,
  "reader": {
    "card_number": "000001",
    "full_name": "John Doe",
    "email": "john@example.com"
  }
}
```

### Returning the book

PATCH /loans/:id/return

Example response:

```json
{
  "id": 2,
  "borrowed_at": "2026-11-19T09:19:00.123Z",
  "due_at": "2026-12-19T09:19:00.123Z",
  "returned_at": "2026-11-19T09:22:14.750Z",
  "reader": {
    "card_number": "000001",
    "full_name": "John Doe",
    "email": "john@example.com"
  }
}
```