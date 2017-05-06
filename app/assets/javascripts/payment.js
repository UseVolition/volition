var stripe = Stripe('pk_test_ybQBLkCEdGFySZ0urTdt91s4');
var elements = stripe.elements();
var form = document.getElementById('payment-form')

var style = {
  base: {
    fontSize: '16px',
    lineHeight: '24px'
  }
}

var card = elements.create('card', {style: style})

card.mount('#card-element')

card.addEventListener('change', function(e) {
  var displayError = document.getElementById('card-errors');

  if (event.error) {
    displayError.textContent = event.error.message;
  } else {
    displayError.textContent = ''
  }
})

var stripeTokenHandler = function(token) {
  var form = document.getElementById('payment-form')
  var hiddenInput = document.createElement('input')

  hiddenInput.setAttribute('type', 'hidden')
  hiddenInput.setAttribute('name', 'stripeToken')
  hiddenInput.setAttribute('value', token.id)

  form.appendChild(hiddenInput)
  form.submit()
}

form.addEventListener('submit', function(e) {
  event.preventDefault()

  stripe.createToken(card).then(function(result) {
    if (result.error) {
      var errorElement = document.getElementById('card-errors')
      errorElement.textContent = result.error.message
    } else {
      stripeTokenHandler(result.token)
    }
  })
})
