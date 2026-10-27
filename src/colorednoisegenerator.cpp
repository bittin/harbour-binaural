#include "colorednoisegenerator.h"

#include <QtMath>
#include <cstring>

namespace
{
    const int DefaultSampleRate = 48000;
}

// ============================================================================
// COLORED NOISE GENERATOR
// ============================================================================

ColoredNoiseGenerator::ColoredNoiseGenerator(QObject *parent)
    : QIODevice(parent),
      m_sampleRate(DefaultSampleRate),
      m_channelCount(2),
      m_noiseType(WhiteNoise)
{
    resetNoiseState();
}

void ColoredNoiseGenerator::setSampleRate(int sampleRate)
{
    if (sampleRate > 0)
        m_sampleRate = sampleRate;
}

int ColoredNoiseGenerator::sampleRate() const
{
    return m_sampleRate;
}

void ColoredNoiseGenerator::setChannelCount(int channelCount)
{
    if (channelCount > 0 && channelCount <= 2)
        m_channelCount = channelCount;
}

int ColoredNoiseGenerator::channelCount() const
{
    return m_channelCount;
}

void ColoredNoiseGenerator::setNoiseType(NoiseType type)
{
    if (m_noiseType == type)
        return;

    m_noiseType = type;
    resetNoiseState();
}

ColoredNoiseGenerator::NoiseType
ColoredNoiseGenerator::noiseType() const
{
    return m_noiseType;
}

void ColoredNoiseGenerator::start()
{
    resetNoiseState();
    open(QIODevice::ReadOnly);
}

qint64 ColoredNoiseGenerator::readData(char *data, qint64 maxlen)
{
    if (!data || maxlen <= 0)
        return 0;

    const qint64 frameSize =
        m_channelCount * sizeof(qint16);

    if (frameSize <= 0)
        return 0;

    const qint64 frameCount =
        maxlen / frameSize;

    if (frameCount <= 0)
        return 0;

    qint16 *samples =
        reinterpret_cast<qint16 *>(data);

    for (qint64 frame = 0;
         frame < frameCount;
         ++frame)
    {
        for (int channel = 0;
             channel < m_channelCount;
             ++channel)
        {
            double value = 0.0;

            switch (m_noiseType)
            {
            case WhiteNoise:
                value = nextWhite(channel);
                break;

            case PinkNoise:
                value = nextPink(channel);
                break;

            case BrownNoise:
                value = nextBrown(channel);
                break;

            case GreyNoise:
                value = nextGrey(channel);
                break;
            }

            /*
             * Final safety limiter.
             */
            value *= noiseGain();

            value = qBound(-1.0, value, 1.0);

            samples[
                frame * m_channelCount + channel
            ] =
                static_cast<qint16>(
                    // MASTER VOLUME Colored Noise
                    value * 16000.0);
        }
    }

    return frameCount * frameSize;
}

qint64 ColoredNoiseGenerator::writeData(
    const char *, qint64)
{
    return 0;
}

/*
 * Per-noise-type loudness calibration.
 *
 * Different noise colors produce different perceived loudness
 * at the same numerical signal level. These fixed gains provide
 * a practical balance between the four noise types without
 * requiring real-time loudness normalization.
 */
double ColoredNoiseGenerator::noiseGain() const
{
    switch (m_noiseType)
    {
    case WhiteNoise:
        return 0.40;

    case PinkNoise:
        return 1.00;

    case BrownNoise:
        return 1.00;

    case GreyNoise:
        return 0.80;
    }

    return 1.0;
}

void ColoredNoiseGenerator::resetNoiseState()
{
    for (int channel = 0;
         channel < 2;
         ++channel)
    {
        /*
         * Independent deterministic seed for
         * left and right channels.
         */
        m_randomState[channel] =
            0x12345678u +
            channel * 0x13579BDFu;

        /*
         * Pink noise filter state.
         */
        for (int i = 0; i < 7; ++i)
            m_pinkState[channel][i] = 0.0;

        /*
         * Brown noise state.
         */
        m_brownState[channel] = 0.0;

        /*
         * Grey noise filter state.
         */
        m_greyLow[channel] = 0.0;
        m_greyMid[channel] = 0.0;
        m_greyHigh[channel] = 0.0;

        m_whiteFiltered[channel] = 0.0;
    }
}

/*
 * ================================================================
 * WHITE NOISE
 * ================================================================
 *
 * Starts from a raw pseudo-random source and applies
 * lightweight smoothing to reduce the aggressive character
 * of unfiltered white noise.
 *
 * The result remains broadband but is intentionally softened
 * for more comfortable long-duration listening.
 */

/*
 * Raw white-noise source.
 *
 * Provides an unsmoothed random signal for algorithms such as
 * Brown noise that require direct integration of white noise.
 * A deterministic, independent state is maintained per channel.
 */
double ColoredNoiseGenerator::nextRawWhite(int channel)
{
    /*
     * 32-bit linear congruential generator.
     */
    m_randomState[channel] =
        1664525u *
        m_randomState[channel]
        + 1013904223u;

    const quint32 randomValue =
        m_randomState[channel];

    /*
     * Convert unsigned 32-bit value to
     * approximately [-1.0, +1.0].
     */
    return (randomValue / 2147483648.0) - 1.0;

}

double ColoredNoiseGenerator::nextWhite(int channel)
{
    const double white =
        nextRawWhite(channel);

    /*
     * Smooth the White noise to reduce the
     * aggressive high-frequency character.
     */
    m_whiteFiltered[channel] =
        m_whiteFiltered[channel] * 0.82
        + white * 0.18;

    return m_whiteFiltered[channel] * 0.82;
}

/*
 * ================================================================
 * PINK NOISE
 * ================================================================
 *
 * Approximately 1/f power spectrum.
 *
 * Roughly -3 dB per octave.
 *
 * Uses a Paul Kellet-style filter built from the smoothed
 * white-noise source to produce a stable pink-noise approximation.
 */
double ColoredNoiseGenerator::nextPink(int channel)
{
    const double white =
        nextWhite(channel);

    double *state =
        m_pinkState[channel];

    state[0] =
        0.99886 * state[0]
        + white * 0.0555179;

    state[1] =
        0.99332 * state[1]
        + white * 0.0750759;

    state[2] =
        0.96900 * state[2]
        + white * 0.1538520;

    state[3] =
        0.86650 * state[3]
        + white * 0.3104856;

    state[4] =
        0.55000 * state[4]
        + white * 0.5329522;

    state[5] =
        -0.7616 * state[5]
        - white * 0.0168980;

    const double pink =
        state[0] +
        state[1] +
        state[2] +
        state[3] +
        state[4] +
        state[5] +
        state[6] +
        white * 0.5362;

    state[6] =
        white * 0.115926;

    /*
     * Gain compensation.
     */
    return pink * 0.11;
}

/*
 * ================================================================
 * BROWN NOISE
 * ================================================================
 *
 * Approximately 1/f^2 power spectrum.
 *
 * Roughly -6 dB per octave.
 *
 * Uses leaky integration of a raw white-noise source to create
 * smooth low-frequency variations while preventing excessive
 * DC drift. The internal output is gain-compensated for perceived
 * loudness before the final output calibration.
 */
double ColoredNoiseGenerator::nextBrown(int channel)
{
    const double white =
        nextRawWhite(channel);

    double &state =
        m_brownState[channel];

    /*
     * Leaky integration of raw white noise.
     *
     * The leakage prevents unlimited DC drift while
     * retaining the characteristic slow movement of
     * Brown noise.
     */
    state =
        state * 0.995
        + white * 0.018;

    /*
     * Keep the internal state within a safe range.
     */
    state =
        qBound(-1.0, state, 1.0);

    /*
     * Perceived loudness compensation.
     */
    return state * 2.8;
}

/*
 * ================================================================
 * GREY NOISE
 * ================================================================
 *
 * Grey noise is psychoacoustic rather than having
 * one universally fixed mathematical spectrum.
 *
 * This implementation starts from pink noise and applies
 * separate low-, mid-, and high-frequency shaping to create
 * a smoother, more perceptually balanced approximation.
 *
 * The result is intended as a practical approximation of
 * equal-loudness-oriented grey noise rather than an exact
 * reproduction of a specific psychoacoustic standard.
 */
double ColoredNoiseGenerator::nextGrey(int channel)
{
    /*
     * Start from Pink noise.
     *
     * Grey noise is commonly described as a noise signal
     * shaped according to human hearing sensitivity.
     */
    const double pink =
        nextPink(channel);

    double &low =
        m_greyLow[channel];

    double &mid =
        m_greyMid[channel];

    double &high =
        m_greyHigh[channel];

    /*
     * Low-frequency component.
     *
     * Slow component retains some of the lower-frequency
     * energy of Pink noise.
     */
    low =
        low * 0.985
        + pink * 0.015;

    /*
     * Mid-frequency component.
     *
     * This region is deliberately given more weight,
     * reflecting the greater sensitivity of human hearing
     * in the mid-frequency range.
     */
    mid =
        mid * 0.80
        + pink * 0.20;

    /*
     * High-frequency component.
     *
     * Faster response keeps the high-frequency contribution
     * controlled without making Grey sound harsh.
     */
    high =
        high * 0.45
        + pink * 0.55;

    /*
     * Psychoacoustic weighting.
     *
     * Keep the low frequencies restrained, emphasize the
     * useful midrange, and retain a smaller high-frequency
     * contribution.
     */
    const double grey =
        low * 0.25
        + mid * 0.60
        + high * 0.15;

    return grey * 2.4;
}
