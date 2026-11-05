local couponCallbacks = {
  ["get-coupons"] = "jg-dealerships:server:get-coupons",
  ["create-coupon"] = "jg-dealerships:server:create-coupon",
  ["update-coupon"] = "jg-dealerships:server:update-coupon",
  ["delete-coupon"] = "jg-dealerships:server:delete-coupon",
  ["generate-coupon-code"] = "jg-dealerships:server:generate-coupon-code",
  ["validate-coupon"] = "jg-dealerships:server:validate-coupon",
}

for nuiCallback, serverCallback in pairs(couponCallbacks) do
  RegisterNUICallback(nuiCallback, function(data, callback)
    callback(lib.callback.await(serverCallback, false, data))
  end)
end
