var stripe = Stripe(JSON.parse(document.getElementById('stripe_params').dataset.attrs).PUBLIC_KEY, {
  locale: 'es-419'
});

var elements = stripe.elements();


// Custom styling can be passed to options when creating an Element.
var style = {
  base: {
    // Add your base input styles here. For example:
    fontSize: '16px',
    color: '#32325d',
  },
};

// Creates individual elements instances
var cardNumberElement = elements.create('cardNumber', {showIcon: true});
var cardExpiryElement = elements.create('cardExpiry');
var cardCvcElement = elements.create('cardCvc');

// Add an instance of an element into a container DOM element
cardNumberElement.mount('#cardNumber-element');
cardExpiryElement.mount('#cardExpiry-element');
cardCvcElement.mount('#cardCvc-element');

function stripeTokenHandler(token) {
  // Insert the token ID into the form so it gets submitted to the server
  var form = document.getElementById('payment-form');
  var hiddenInput = document.createElement('input');
  hiddenInput.setAttribute('type', 'hidden');
  hiddenInput.setAttribute('name', 'stripeToken');
  hiddenInput.setAttribute('value', token.id);
  form.appendChild(hiddenInput);
  console.log(token.id)

  // Submit the form
  form.submit();
}

function createToken() {
  stripe.createToken(cardNumberElement).then(function(result) {
    if (result.error) {
      document.getElementById('loading-spinner').style.display = 'none'
      document.getElementById('processing-payment').style.display = 'none'
      document.getElementById('checkout-fields').style.display = 'block'
      // Inform the user if there was an error
      var errorElement = document.getElementById('card-errors');
      errorElement.textContent = result.error.message;
    } else {
      document.getElementById('loading-spinner').style.display = 'none'
      document.getElementById('processing-payment').style.display = 'none'
      document.getElementById('payment-successful').style.display = 'block'
      // Send the token to your server
      stripeTokenHandler(result.token);
    }
  });
  };

  // Create a token when the form is submitted.
  var form = document.getElementById('payment-form');
  form.addEventListener('submit', function(e) {
  e.preventDefault();
  createToken();
});