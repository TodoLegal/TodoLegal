//validate if input fields were filled with the right format and activates the popover when needed

console.log("formValidator is loaded");
var name = document.getElementById("name");
if(name){

    bootstrapValidate(name, 'required:Debes ingresar tu nombre', function (isValid){
    if(isValid && name.value.includes("https") == false)
    {
        $('#nextButton').unbind();
        $('#nextButton').popover('hide')
    } else
    {
        $('#nextButton').click(function (e) {
        $('#nextButton').popover('show')
        e.preventDefault();
        e.stopPropagation();
        });
    }
    });
}

var lastName = document.getElementById("lastName");
if(lastName){
    bootstrapValidate(lastName, 'required:Debes ingresar tu apellido', function (isValid){
    if(isValid && lastName.value.includes("https") == false)
    {
        $('#nextButton').unbind();
        $('#nextButton').popover('hide')
    } else
    {
        $('#nextButton').click(function (e) {
        $('#nextButton').popover('show');
        e.preventDefault();
        e.stopPropagation();
        });
    }
    });
}

var email = document.getElementById("email")
if(email){
    bootstrapValidate(email, 'email:Debes ingresar un correo válido', function (isValid){
    if(isValid)
    {
        $('#nextButton').unbind();
        $('#nextButton').popover('hide')
    } else
    {
        $('#nextButton').click(function (e) {
        $('#nextButton').popover('show')
        e.preventDefault();
        e.stopPropagation();
        });
    }
    });
}

var confirmEmail = document.getElementById("confirmEmail");
if(confirmEmail){
    bootstrapValidate(confirmEmail, 'matches:#email:Tus correos deben ser iguales', function (isValid){
    if(isValid)
    {
        $('#nextButton').unbind();
        $('#nextButton').popover('hide')
    } else
    {
        $('#nextButton').click(function (e) {
        $('#nextButton').popover('show')
        e.preventDefault();
        e.stopPropagation();
        });
    }
    });
}

var email2 = document.getElementById("email2")
if(email2){
    bootstrapValidate(email2, 'email:Debes ingresar un correo válido', function (isValid){
    if(isValid)
    {
        $('#nextButton').unbind();
        $('#nextButton').popover('hide')
    } else
    {
        $('#nextButton').click(function (e) {
        $('#nextButton').popover('show')
        e.preventDefault();
        e.stopPropagation();
        });
    }
    });
}

var password = document.getElementById("password");
if(password){
    bootstrapValidate(password, 'min:6:Debes ingresar una contraseña válida',function (isValid){
    if(isValid)
    {
        $('#nextButton').unbind();
        $('#nextButton').popover('hide')
    } else
    {
        $('#nextButton').click(function (e) {
        $('#nextButton').popover('show')
        e.preventDefault();
        e.stopPropagation();
        });
    }
    });
}

var confirmPassword = document.getElementById("confirmPassword");
if(confirmPassword){
    bootstrapValidate(confirmPassword, 'matches:#password:Tus contraseñas deben ser iguales', function (isValid){
    if(isValid)
    {
        $('#nextButton').unbind();
        $('#nextButton').popover('hide')
    } else
    {
        $('#nextButton').click(function (e) {
        $('#nextButton').popover('show')
        e.preventDefault();
        e.stopPropagation();
        });
    }
    });
}