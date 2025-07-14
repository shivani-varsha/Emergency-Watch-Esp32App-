#include "config.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/timers.h"
#include "freertos/queue.h"
#include <soc/rtc.h>
#include "esp_wifi.h"
#include "esp_sleep.h"
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "gui.h"

#define G_EVENT_VBUS_PLUGIN         _BV(0)
#define G_EVENT_VBUS_REMOVE         _BV(1)
#define G_EVENT_CHARGE_DONE         _BV(2)
#define G_EVENT_WIFI_SCAN_START     _BV(3)
#define G_EVENT_WIFI_SCAN_DONE      _BV(4)
#define G_EVENT_WIFI_CONNECTED      _BV(5)
#define G_EVENT_WIFI_BEGIN          _BV(6)
#define G_EVENT_WIFI_OFF            _BV(7)

enum {
    Q_EVENT_WIFI_SCAN_DONE,
    Q_EVENT_WIFI_CONNECT,
    Q_EVENT_BMA_INT,
    Q_EVENT_AXP_INT,
};

#define DEFAULT_SCREEN_TIMEOUT  30*1000

#define WATCH_FLAG_SLEEP_MODE   _BV(1)
#define WATCH_FLAG_SLEEP_EXIT   _BV(2)
#define WATCH_FLAG_BMA_IRQ      _BV(3)
#define WATCH_FLAG_AXP_IRQ      _BV(4)

QueueHandle_t g_event_queue_handle = NULL;
EventGroupHandle_t g_event_group = NULL;
bool lenergy = false;
TTGOClass *ttgo;

bool isSettingsScreen = false;

void setupNetwork()
{
    WiFi.mode(WIFI_STA);
    WiFi.onEvent([](WiFiEvent_t event, WiFiEventInfo_t info) {
        xEventGroupClearBits(g_event_group, G_EVENT_WIFI_CONNECTED);
    }, WiFiEvent_t::ARDUINO_EVENT_WIFI_STA_DISCONNECTED);

    WiFi.onEvent([](WiFiEvent_t event, WiFiEventInfo_t info) {
        uint8_t data = Q_EVENT_WIFI_SCAN_DONE;
        xQueueSend(g_event_queue_handle, &data, portMAX_DELAY);
    }, WiFiEvent_t::ARDUINO_EVENT_WIFI_SCAN_DONE);

    WiFi.onEvent([](WiFiEvent_t event, WiFiEventInfo_t info) {
        xEventGroupSetBits(g_event_group, G_EVENT_WIFI_CONNECTED);
    }, WiFiEvent_t::ARDUINO_EVENT_WIFI_STA_CONNECTED);

    WiFi.onEvent([](WiFiEvent_t event, WiFiEventInfo_t info) {
        wifi_connect_status(true);
    }, WiFiEvent_t::ARDUINO_EVENT_WIFI_STA_GOT_IP);
}

void low_energy()
{
    if (ttgo->bl->isOn()) {
        ttgo->closeBL();
        ttgo->stopLvglTick();
        ttgo->bma->enableStepCountInterrupt(false);
        ttgo->displaySleep();
        if (!WiFi.isConnected()) {
            lenergy = true;
            WiFi.mode(WIFI_OFF);
            Serial.println("ENTER IN LIGHT SLEEEP MODE");
            gpio_wakeup_enable ((gpio_num_t)AXP202_INT, GPIO_INTR_LOW_LEVEL);
            gpio_wakeup_enable ((gpio_num_t)BMA423_INT1, GPIO_INTR_HIGH_LEVEL);
            esp_sleep_enable_gpio_wakeup ();
            esp_light_sleep_start();
        }
    } else {
        ttgo->startLvglTick();
        ttgo->displayWakeup();
        ttgo->rtc->syncToSystem();
        updateStepCounter(ttgo->bma->getCounter());
        updateBatteryLevel();
        updateBatteryIcon(LV_ICON_CALCULATION);
        lv_disp_trig_activity(NULL);
        ttgo->openBL();
        ttgo->bma->enableStepCountInterrupt();
    }
}

static void event_handler(lv_obj_t *obj, lv_event_t event)
{
    if (event == LV_EVENT_CLICKED) {
        if (strcmp(lv_label_get_text(lv_obj_get_child(obj, NULL)), "Settings") == 0) {
            Serial.printf("Clicked Settings\n");
            isSettingsScreen = false;
            setupMainGUI();
        }
    } else if (event == LV_EVENT_VALUE_CHANGED) {
        Serial.printf("Toggled\n");
    }
}

static void emergency_handler(lv_obj_t *obj, lv_event_t event)
{
    if (event == LV_EVENT_CLICKED) {
        Serial.printf("Emergency button clicked\n");

        // Initiate Wi-Fi scan
        WiFi.scanNetworks(true);
    }
}

static void back_button_handler(lv_obj_t *obj, lv_event_t event)
{
    if (event == LV_EVENT_CLICKED) {
        Serial.printf("Back button clicked\n");
        setupSettingsGUI();
    }
}

void setupSettingsGUI()
{
    lv_obj_t *label;

    lv_obj_t *btn1 = lv_btn_create(lv_scr_act(), NULL);
    lv_obj_set_event_cb(btn1, event_handler);
    lv_obj_align(btn1, NULL, LV_ALIGN_CENTER, 0, -40);

    label = lv_label_create(btn1, NULL);
    lv_label_set_text(label, "Settings");

    lv_obj_t *btn2 = lv_btn_create(lv_scr_act(), NULL);
    lv_obj_set_event_cb(btn2, emergency_handler);
    lv_obj_align(btn2, NULL, LV_ALIGN_CENTER, 0, 40);
    lv_btn_set_checkable(btn2, true);
    lv_btn_toggle(btn2);
    lv_btn_set_fit2(btn2, LV_FIT_NONE, LV_FIT_TIGHT);

    label = lv_label_create(btn2, NULL);
    lv_label_set_text(label, "Emergency");
}

void setupMainGUI()
{
    lv_obj_clean(lv_scr_act());  // Clear the current screen

    // Your existing main GUI setup code
    setupGui();

    // Add Back button to return to Settings and Emergency screen
    lv_obj_t *back_btn = lv_btn_create(lv_scr_act(), NULL);
    lv_obj_set_event_cb(back_btn, back_button_handler);
    lv_obj_align(back_btn, NULL, LV_ALIGN_IN_TOP_LEFT, 10, 10);

    lv_obj_t *label = lv_label_create(back_btn, NULL);
    lv_label_set_text(label, "Back");
}

void setup()
{
    Serial.begin(115200);

    g_event_queue_handle = xQueueCreate(20, sizeof(uint8_t));
    g_event_group = xEventGroupCreate();

    ttgo = TTGOClass::getWatch();

    ttgo->begin();
    ttgo->power->adc1Enable(AXP202_BATT_VOL_ADC1 | AXP202_BATT_CUR_ADC1 | AXP202_VBUS_VOL_ADC1 | AXP202_VBUS_CUR_ADC1, AXP202_ON);
    ttgo->power->enableIRQ(AXP202_VBUS_REMOVED_IRQ | AXP202_VBUS_CONNECT_IRQ | AXP202_CHARGING_FINISHED_IRQ, AXP202_ON);
    ttgo->power->clearIRQ();
    ttgo->lvgl_begin();

    ttgo->bma->attachInterrupt();
    pinMode(BMA423_INT1, INPUT);
    attachInterrupt(BMA423_INT1, [] {
        BaseType_t xHigherPriorityTaskWoken = pdFALSE;
        uint8_t data = Q_EVENT_BMA_INT;
        xQueueSendFromISR(g_event_queue_handle, &data, &xHigherPriorityTaskWoken);
        if (xHigherPriorityTaskWoken)
        {
            portYIELD_FROM_ISR ();
        }
    }, RISING);

    pinMode(AXP202_INT, INPUT);
    attachInterrupt(AXP202_INT, [] {
        BaseType_t xHigherPriorityTaskWoken = pdFALSE;
        uint8_t data = Q_EVENT_AXP_INT;
        xQueueSendFromISR(g_event_queue_handle, &data, &xHigherPriorityTaskWoken);
        if (xHigherPriorityTaskWoken)
        {
            portYIELD_FROM_ISR ();
        }
    }, FALLING);

    ttgo->rtc->check();
    ttgo->rtc->syncToSystem();

#ifdef LILYGO_WATCH_HAS_BUTTON
    ttgo->button->setLongClickHandler([]() {
        Serial.println("Pressed Restart Button,Restart now ...");
        delay(1000);
        esp_restart();
    });
#endif

    setupNetwork();

    setupSettingsGUI();
    isSettingsScreen = true;

    lv_disp_trig_activity(NULL);

#ifdef LILYGO_WATCH_HAS_BUTTON
    lv_task_create([](lv_task_t *args) {
        ttgo->button->loop();
    }, 30, 1, nullptr);
#endif

    ttgo->openBL();
}

void loop()
{
    bool  rlst;
    uint8_t data;
    if (xQueueReceive(g_event_queue_handle, &data, 5 / portTICK_RATE_MS) == pdPASS) {
        switch (data) {
        case Q_EVENT_BMA_INT:
            do {
                rlst =  ttgo->bma->readInterrupt();
            } while (!rlst);
            if (ttgo->bma->isStepCounter()) {
                updateStepCounter(ttgo->bma->getCounter());
            }
            break;
        case Q_EVENT_AXP_INT:
            ttgo->power->readIRQ();
            if (ttgo->power->isVbusPlugInIRQ()) {
                updateBatteryIcon(LV_ICON_CHARGE);
            }
            if (ttgo->power->isVbusRemoveIRQ()) {
                updateBatteryIcon(LV_ICON_CALCULATION);
            }
            if (ttgo->power->isChargingDoneIRQ()) {
                updateBatteryIcon(LV_ICON_CALCULATION);
            }
            if (ttgo->power->isPEKShortPressIRQ()) {
                ttgo->power->clearIRQ();
                low_energy();
                return;
            }
            ttgo->power->clearIRQ();
            break;
        case Q_EVENT_WIFI_SCAN_DONE: {
            int16_t len = WiFi.scanComplete();
            if (len > 0) {
                DynamicJsonDocument doc(1024);
                JsonArray wifiAccessPoints = doc.createNestedArray("wifiAccessPoints");

                for (int i = 0; i < len; ++i) {
                    JsonObject accessPoint = wifiAccessPoints.createNestedObject();
                    accessPoint["macAddress"] = WiFi.BSSIDstr(i);
                    accessPoint["signalStrength"] = WiFi.RSSI(i);
                }

                String jsonStr;
                serializeJson(doc, jsonStr);

                HTTPClient http;
                http.begin("http://192.168.139.32:3000/emergency"); // Replace with your server's IP and port
                http.addHeader("Content-Type", "application/json");
                int httpResponseCode = http.POST(jsonStr);

                if (httpResponseCode > 0) {
                    String response = http.getString();
                    Serial.println("HTTP Response code: " + String(httpResponseCode));
                    Serial.println("Response: " + response);
                } else {
                    Serial.println("Error on sending POST: " + String(httpResponseCode));
                }

                http.end();
            } else {
                Serial.println("No WiFi networks found");
            }
            break;
        }
        default:
            break;
        }
    }
    if (lv_disp_get_inactive_time(NULL) < DEFAULT_SCREEN_TIMEOUT) {
        lv_task_handler();
    } else {
        low_energy();
    }
}
