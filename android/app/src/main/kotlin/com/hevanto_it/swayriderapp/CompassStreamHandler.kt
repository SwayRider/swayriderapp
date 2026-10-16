package com.hevanto_it.swayriderapp

import android.app.Activity
import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.SystemClock
import android.view.Surface
import io.flutter.plugin.common.EventChannel
import kotlin.math.atan2
import kotlin.math.hypot

/**
 * Streams the device's compass heading to Dart: `{heading, accuracy}` maps, at
 * most about 30 a second, only while Dart listens.
 *
 * `heading` is degrees clockwise from magnetic north of where the user points the
 * device: the top of the screen when the phone is held flat, the back of the phone
 * when it is held upright (on a handlebar mount, say). Whichever of the two points
 * more horizontally is used, so there is no jump between the two postures (they
 * coincide at 45 degrees). The screen rotation is accounted for.
 *
 * `accuracy` is the plus or minus error in degrees, or null while unknown. It comes
 * from the rotation vector sensor's own estimate when the phone provides one,
 * otherwise from the sensor status (high 15, medium 30, low 45); an unreliable
 * sensor reports 90 so that Dart ignores the reading and asks for calibration.
 */
class CompassStreamHandler(private val activity: Activity) :
    EventChannel.StreamHandler, SensorEventListener {

    private val sensorManager =
        activity.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val rotationSensor: Sensor? =
        sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)

    private var sink: EventChannel.EventSink? = null
    private var lastSentAt = 0L

    private val rotationMatrix = FloatArray(9)
    private val remapped = FloatArray(9)

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (rotationSensor == null) {
            events?.error("NO_SENSOR", "This device has no rotation vector sensor", null)
            events?.endOfStream()
            return
        }
        sink = events
        sensorManager.registerListener(this, rotationSensor, SensorManager.SENSOR_DELAY_GAME)
    }

    override fun onCancel(arguments: Any?) {
        sensorManager.unregisterListener(this)
        sink = null
    }

    override fun onSensorChanged(event: SensorEvent) {
        val sink = sink ?: return
        val now = SystemClock.elapsedRealtime()
        if (now - lastSentAt < MIN_INTERVAL_MS) return
        lastSentAt = now

        // Some phones (certain Samsungs) deliver more values than the conversion
        // accepts (it only needs the first four); others only three, and then
        // it must not see a stale fourth.
        val values = if (event.values.size > 4) event.values.copyOf(4) else event.values
        SensorManager.getRotationMatrixFromVector(rotationMatrix, values)

        val (axisX, axisY) = when (displayRotation()) {
            Surface.ROTATION_90 -> SensorManager.AXIS_Y to SensorManager.AXIS_MINUS_X
            Surface.ROTATION_180 -> SensorManager.AXIS_MINUS_X to SensorManager.AXIS_MINUS_Y
            Surface.ROTATION_270 -> SensorManager.AXIS_MINUS_Y to SensorManager.AXIS_X
            else -> SensorManager.AXIS_X to SensorManager.AXIS_Y
        }
        SensorManager.remapCoordinateSystem(rotationMatrix, axisX, axisY, remapped)

        // Column j of the matrix is the screen axis j in world coordinates
        // (east, north, up): screen top = column 1, out of the screen = column 2.
        val topEast = remapped[1]
        val topNorth = remapped[4]
        val backEast = -remapped[2]
        val backNorth = -remapped[5]
        val heading = if (hypot(topEast, topNorth) >= hypot(backEast, backNorth)) {
            Math.toDegrees(atan2(topEast, topNorth).toDouble())
        } else {
            Math.toDegrees(atan2(backEast, backNorth).toDouble())
        }

        sink.success(
            mapOf(
                "heading" to ((heading % 360.0) + 360.0) % 360.0,
                "accuracy" to accuracyDegrees(event),
            )
        )
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    private fun accuracyDegrees(event: SensorEvent): Double? {
        val fromStatus: Double? = when (event.accuracy) {
            SensorManager.SENSOR_STATUS_ACCURACY_HIGH -> 15.0
            SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM -> 30.0
            SensorManager.SENSOR_STATUS_ACCURACY_LOW -> 45.0
            SensorManager.SENSOR_STATUS_UNRELIABLE -> 90.0
            else -> null
        }
        if (fromStatus == UNRELIABLE_DEGREES) return fromStatus
        // The sensor's own estimate (radians) is the fifth value, -1 when absent.
        val estimated = if (event.values.size >= 5 && event.values[4] >= 0f) {
            Math.toDegrees(event.values[4].toDouble())
        } else {
            null
        }
        return estimated ?: fromStatus
    }

    @Suppress("DEPRECATION")
    private fun displayRotation(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            activity.display?.rotation ?: Surface.ROTATION_0
        } else {
            activity.windowManager.defaultDisplay.rotation
        }

    companion object {
        const val CHANNEL = "com.hevanto_it.swayriderapp/compass"
        private const val MIN_INTERVAL_MS = 30L
        private const val UNRELIABLE_DEGREES = 90.0
    }
}
