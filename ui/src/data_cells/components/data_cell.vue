<template>
  <DateTime
    v-if="isDateTime"
    :value="stringValue"
  />
  <DataImage
    v-else-if="isImage"
    :value="stringValue"
  />
  <DataUrl
    v-else-if="isUrl"
    :truncate="textTruncate"
    :value="stringValue"
  />
  <DataTag
    v-else-if="isTag"
    :value="stringValue"
  />
  <DataEmail
    v-else-if="isEmail"
    :truncate="textTruncate"
    :value="value"
  />
  <DataPhone
    v-else-if="isPhone"
    :truncate="textTruncate"
    :value="value"
  />
  <DataBoolean
    v-else-if="isBoolean"
    :value="value"
  />
  <DataText
    v-else
    :truncate="textTruncate"
    :value="stringValue"
  />
</template>

<script>
import DateTime from './date_time'
import DataText from './text'
import DataUrl from './url'
import DataTag from './tag'
import DataImage from './image'
import DataBoolean from './boolean'
import DataEmail from './email'
import DataPhone from './phone'

import DataTypes from '../scripts/data_types'

export default {
  name: 'DataCell',
  components: {
    DataText,
    DateTime,
    DataUrl,
    DataTag,
    DataImage,
    DataBoolean,
    DataEmail,
    DataPhone
  },
  props: {
    value: {
      type: [String, Number, Object, Boolean],
      required: false,
      default: ''
    },
    type: {
      type: String,
      required: false,
      default: DataTypes.TEXT
    },
    textTruncate: {
      type: Boolean,
      required: false,
      default: true
    }
  },
  computed: {
    stringValue () {
      if (this.value && typeof this.value === 'object') {
        return JSON.stringify(this.value, null, '  ')
      } else if (typeof this.value === 'number') {
        return this.value.toString()
      } else {
        return (this.value || '').toString()
      }
    },
    isDateTime () {
      return this.type === DataTypes.DATE_TIME || this.type === DataTypes.TIMESTAMP
    },
    isTag () {
      return this.type === DataTypes.TAG
    },
    isPhone () {
      return !!this.stringValue.match(/^\+[\d\s()-]{5,}$/)
    },
    isEmail () {
      return !!this.stringValue.match(/^[\w.]+@\w+\.\w{2,3}/)
    },
    isBoolean () {
      return typeof this.value === 'boolean'
    },
    isImage () {
      return this.isUrl && !!this.stringValue.match(/\.(jpg|png|jpeg|wepb|svg)$/)
    },
    isUrl () {
      return !!this.stringValue.match(/^https?:\/\//i)
    }
  },
  mounted () {
  }
}
</script>

<style lang="scss">

</style>