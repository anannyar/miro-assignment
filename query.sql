-- Joining the in-app pricing views to the upgrade dataset on user_id and timeframe
WITH in_app_details AS
(
SELECT 
       click_upgrade.user_id                                              AS click_upgrade_user_id,
       click_upgrade.time                                                 AS click_upgrade_time,
       click_upgrade.click_upgrade_from,
       show_inapp_pricing.user_id                                         AS show_inapp_pricing_user_id,
       show_inapp_pricing.time                                            AS show_inapp_pricing_time,
       TIMESTAMP_DIFF(show_inapp_pricing.time,click_upgrade.time ,minute) AS time_diff_show_inapp_pricing
FROM  `miro-assignment.miro_task_3.click_upgrade` click_upgrade
LEFT JOIN `miro-assignment.miro_task_3.show_inapp_pricing` show_inapp_pricing
ON click_upgrade.user_id = show_inapp_pricing.user_id 
AND show_inapp_pricing.time >= click_upgrade.time 
)
-- selecting the time from in-app pricing views that is closest to the upgrade time
, ranked_in_app AS
(
select * except(show_inapp_pricing_time), 
       min(show_inapp_pricing_time) AS show_inapp_pricing_time  
       from in_app_details 
       group by 1,2,3,4,5

)
-- Joining the payment details views to the in-app pricing views dataset on user_id and timeframe
, payment_details AS
(
SELECT 
       ranked_in_app.*,
       viewed_payment_details.user_id                                              AS viewed_payment_details_user_id,
       viewed_payment_details.time                                                 AS viewed_payment_details_time,
       TIMESTAMP_DIFF(viewed_payment_details.time,show_inapp_pricing_time ,minute) AS time_diff_viewed_payment_details
FROM  ranked_in_app ranked_in_app
LEFT JOIN `miro-assignment.miro_task_3.viewed_payment_details`  viewed_payment_details
ON show_inapp_pricing_user_id = viewed_payment_details.user_id 
AND viewed_payment_details.time >= show_inapp_pricing_time
)
-- selecting the time from payment details views that is closest to the in-app pricing view time
, ranked_payment AS
(
SELECT * EXCEPT(viewed_payment_details_time), 
         MIN(viewed_payment_details_time) AS viewed_payment_details_time  
         FROM payment_details 
         GROUP BY 1,2,3,4,5,6,7,8
)
-- Joining the subscription created details to the payment details views dataset on user_id and timeframe
, subsciption_details AS
(
SELECT 
       ranked_payment.*,
       subscription_created.user_id                                                  AS subscription_created_user_id,
       subscription_created.time                                                     AS subscription_created_time,
       TIMESTAMP_DIFF(subscription_created.time,viewed_payment_details_time ,minute) AS time_diff_subsciption
FROM  ranked_payment ranked_payment
LEFT JOIN `miro-assignment.miro_task_3.subscription_created`   subscription_created
ON viewed_payment_details_user_id = subscription_created.user_id 
AND subscription_created.time >= viewed_payment_details_time
)
-- selecting the time of subscription creation that is closest to the payment details view time
, ranked_subscription AS
(
SELECT * EXCEPT(subscription_created_time), 
         MIN(subscription_created_time) AS subscription_created_time  
         FROM subsciption_details 
         GROUP BY 1,2,3,4,5,6,7,8,9,10,11
)
--creating tags for each step of the funnel
,tags AS
(
SELECT *, 
       CASE WHEN show_inapp_pricing_user_id     IS NOT NULL THEN 1 ELSE 0 END AS seen_inapp_pricing,
       CASE WHEN viewed_payment_details_user_id IS NOT NULL THEN 1 ELSE 0 END AS seen_payment_details,
       CASE WHEN subscription_created_user_id   IS NOT NULL THEN 1 ELSE 0 END AS subscribed
FROM ranked_subscription
)
SELECT *
FROM tags


