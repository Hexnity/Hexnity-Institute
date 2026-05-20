# Hexnity Institute Website

This project is a Craft CMS site for Hexnity Institute.

## Tech Stack

- Craft CMS 5
- Twig templates
- Tailwind CSS

## Project Structure

- `templates/index.twig`: Shared base layout
- `templates/_partials/header.twig`: Shared header
- `templates/_partials/footer.twig`: Shared footer
- `templates/pages/home.twig`: Home page template
- `templates/pages/about-us.twig`: About Us page template
- `templates/pages/how-we-work.twig`: How We Work page template
- `templates/pages/contact.twig`: Contact page template

## Local Development

1. Install PHP dependencies:
   - `composer install`
2. Install frontend dependencies:
   - `npm install`
3. Build CSS:
   - `npm run build` (or your configured Tailwind build command)
4. Run Craft in your local server setup.

## Content Management

Page content and routing should be managed from the Craft admin panel by assigning section templates.

## License

This project is licensed under the MIT License. See `LICENSE` for details.
