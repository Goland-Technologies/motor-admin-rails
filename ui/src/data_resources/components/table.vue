<template>
  <div>
    <div
      class="row"
      :style="{ margin: '10px 0' }"
    >
      <div class="col-6 d-flex align-items-center">
        <VButton
          v-if="withResize"
          icon="md-resize"
          size="small"
          type="dashed"
          class="me-2 bg-transparent"
          @click="$emit('click-resize')"
        />
        <span
          v-if="withTitle && !selectedRows.length"
          class="fs-4 fw-bold nowrap"
        >{{ title }}
          <template v-if="currentScope">
            ({{ currentScope.display_name }})
          </template>
        </span>
        <ResourceActions
          v-if="selectedRows.length"
          :resources="selectedRows"
          :with-deselect="true"
          :resource-name="model.name"
          :label="`Actions (${selectedRows.length})`"
          @start-action="isLoading = true"
          @finish-action="loadDataAndCount"
        />
      </div>
      <div class="col-6 d-flex justify-content-end">
        <ResourceSearch
          v-model="searchQuery"
          style="max-width: 400px"
          class="mx-1"
          :placeholder="`Search ${(association?.display_name || model.display_name).toLowerCase()}...`"
          @search="applySearch"
        />
        <Badge
          :count="filtersCount"
          type="primary"
        >
          <VButton
            icon="ios-funnel"
            class="mx-1 bg-white"
            @click="openFiltersModal"
          />
        </Badge>
        <NewResourceButton
          class="mx-1"
          :model="model"
          :association="association"
          :parent-resource="associationParams ? { name: resourceName, id: associationParams.id } : null"
          @success="loadDataAndCount"
        />
      </div>
    </div>
    <template v-if="!isReloading">
      <DataTable
        :data="rows"
        :loading="isLoading"
        :columns="columns"
        :style="{ height: height, paddingBottom: '1px' }"
        :sort-params="sortParams"
        @sort-change="applySort"
        @row-click="onRowClick"
      />
      <div class="text-center border-top bg-white p-1">
        <Pagination
          :current="paginationParams.current"
          :total="paginationParams.total"
          :page-size="paginationParams.pageSize"
          :page-size-opts="paginationParams.pageSizeOpts"
          size="small"
          show-sizer
          show-elevator
          show-total
          @update:current="paginationParams.current = $event"
          @update:page-size="paginationParams.pageSize = $event"
          @on-change="onPageChange"
          @on-page-size-change="onPageSizeChange"
        />
      </div>
    </template>
    <div
      v-if="isReloading"
      :style="{ height: height, paddingBottom: '1px', position: 'relative' }"
    >
      <Spin
        fix
      />
    </div>
  </div>
</template>

<script>
import api from 'api'
import { reactive } from 'vue'
import { modelNameMap } from '../scripts/schema'
import DataTable from 'data_tables/components/table'
import ResourceSearch from './search'
import ResourceActions from './actions'
import NewResourceButton from './new_button'
import FiltersModal from './filters_modal'

import { truncate } from 'utils/scripts/string'

import DataTypes from 'data_cells/scripts/data_types'

const defaultPaginationParams = {
  current: 1,
  pageSize: 20,
  total: 0,
  pageSizeOpts: [20, 50, 100, 250, 500]
}

const defaultSortParams = {
  order: 'desc',
  key: 'id'
}

const itemsCountCache = reactive({})

export default {
  name: 'ResourceTable',
  components: {
    DataTable,
    ResourceSearch,
    ResourceActions,
    NewResourceButton
  },
  props: {
    resourceName: {
      type: String,
      required: true
    },
    height: {
      type: String,
      required: false,
      default: '500px'
    },
    withTitle: {
      type: Boolean,
      required: false,
      default: false
    },
    withResize: {
      type: Boolean,
      required: false,
      default: false
    },
    associationParams: {
      type: Object,
      require: false,
      default: null
    }
  },
  emits: ['click-resize'],
  data () {
    return {
      isLoading: true,
      isReloading: true,
      rows: [],
      sortParams: { ...defaultSortParams },
      filterParams: [],
      searchQuery: '',
      paginationParams: { ...defaultPaginationParams }
    }
  },
  computed: {
    currentScope () {
      return this.model.scopes.find((scope) => scope.name === this.$route.query?.scope)
    },
    routeQueryParams () {
      const query = {}

      if (Object.keys(this.filterParams).length) {
        query.filter = this.filterParams
      }

      if (this.sortParams?.key &&
        (this.sortParams.key !== defaultSortParams.key ||
        this.sortParams.order !== defaultSortParams.order)) {
        query.sort = `${this.sortParams.order === 'desc' ? '-' : ''}${this.sortParams.key}`
      }

      if (this.searchQuery) {
        query.q = this.searchQuery
      }

      if (this.$route.query?.scope) {
        query.scope = this.$route.query?.scope
      }

      if (this.paginationParams.pageSize !== defaultPaginationParams.pageSize) {
        query.per_page = this.paginationParams.pageSize
      }

      if (this.paginationParams.current !== 1) {
        query.page = this.paginationParams.current
      }

      return query
    },
    filtersCount () {
      return this.filterParams.filter((f) => f !== 'OR').length
    },
    title () {
      return truncate(this.association?.display_name || this.model.display_name, 60)
    },
    itemsCountCacheKey () {
      return JSON.stringify({
        ...this.queryParams,
        page: {}
      })
    },
    selectedRows () {
      return this.rows.filter((row) => row._selected)
    },
    queryPath () {
      if (this.associationParams) {
        return [
          'data',
          modelNameMap[this.resourceName].slug,
          this.associationParams.id,
          this.associationParams.name
        ].join('/')
      } else {
        return `data/${this.model.slug}`
      }
    },
    queryParams () {
      const params = {
        filter: this.filterParams,
        fields: {
          [this.model.name]: this.columns.map((e) => e.key)
        },
        page: {
          limit: this.paginationParams.pageSize,
          offset: this.paginationParams.pageSize * (this.paginationParams.current - 1)
        }
      }

      if (this.sortParams.key) {
        params.sort = `${this.sortParams.order === 'desc' ? '-' : ''}${this.sortParams.key}`
      }

      if (this.includeParams) {
        params.include = this.includeParams
      }

      if (this.searchQuery) {
        params.q = this.searchQuery
      }

      if (this.$route.query?.scope) {
        params.scope = this.$route.query?.scope
      }

      return params
    },
    includeParams () {
      return this.model.columns.map((column) => {
        return column.reference?.name
      }).filter(Boolean).join(',')
    },
    association () {
      if (this.associationParams?.name) {
        return modelNameMap[this.resourceName].associations.find((assoc) => {
          return assoc.slug === this.associationParams.name
        })
      } else {
        return null
      }
    },
    model () {
      if (this.association) {
        const assocSchemaName = this.association.model_name

        return modelNameMap[assocSchemaName]
      } else {
        return modelNameMap[this.resourceName]
      }
    },
    columns () {
      return this.model.columns.map((column) => {
        const type = column.validators.find((v) => v.includes?.length) ? DataTypes.TAG : column.column_type

        if (column.reference?.name !== modelNameMap[this.resourceName].name &&
            ['read_only', 'read_write'].includes(column.access_type)) {
          return {
            key: column.name,
            title: column.display_name,
            reference: column.reference,
            type
          }
        } else {
          return null
        }
      }).filter(Boolean)
    }
  },
  watch: {
    '$route' (to, from) {
      if (!to.params.doNotWatch &&
        to.name === from.name &&
        JSON.stringify(to.params.fragments) === JSON.stringify(from.params.fragments) &&
        (JSON.stringify(to.query) !== JSON.stringify(from.query))) {
        this.assignFromQueryParams(to.query)
        this.loadDataAndCount()
      }
    },
    columns: {
      deep: true,
      handler (newValue, oldValue) {
        if (newValue.length > oldValue.length) {
          this.loadData()
        }
      }
    }
  },
  mounted () {
    this.assignCachedItemsCount()
    this.assignFromQueryParams(this.$route.query)
    this.loadDataAndCount()
  },
  methods: {
    openFiltersModal () {
      this.$Drawer.open(FiltersModal, {
        filters: this.filterParams,
        model: this.model,
        onCancel: () => {
          this.$Drawer.remove()
        },
        onApply: (filters) => {
          this.filterParams = filters
          this.paginationParams.current = 1
          this.pushQueryParams()
          this.loadDataAndCount()
          this.$Drawer.remove()
        }
      }, {
        title: `${this.model.display_name} Filters`,
        className: 'drawer-no-bottom-padding',
        closable: true
      })
    },
    assignFromQueryParams (query = {}) {
      this.filterParams = query.filter || []
      this.searchQuery = query.q || ''

      if (query.sort) {
        this.sortParams = {
          order: query.sort.startsWith('-') ? 'desc' : 'asc',
          key: query.sort.replace(/^-/, '')
        }
      } else {
        this.sortParams = { ...defaultSortParams }
      }

      this.paginationParams.current = parseInt(query.page) || 1
      this.paginationParams.pageSize = parseInt(query.per_page) || defaultPaginationParams.pageSize
    },
    loadDataAndCount () {
      return Promise.all([
        this.loadData(),
        this.loadItemsCount()
      ])
    },
    assignCachedItemsCount () {
      const count = itemsCountCache[this.itemsCountCacheKey]

      if (count) {
        this.paginationParams.total = count
      }
    },
    onPageChange () {
      this.pushQueryParams()
      this.loadData()
    },
    onPageSizeChange () {
      this.pushQueryParams()
      this.loadData()
    },
    applySearch () {
      this.paginationParams.current = 1

      this.pushQueryParams()

      this.loadDataAndCount()
    },
    applySort (sort) {
      this.sortParams = sort

      this.pushQueryParams()
      this.loadData()
    },
    pushQueryParams () {
      this.$router.push({ query: this.routeQueryParams, params: { doNotWatch: true } })
    },
    onRowClick (value) {
      this.$router.push({
        name: 'resources',
        params: {
          fragments: [...this.$route.params.fragments, value.id]
        }
      })
    },
    loadItemsCount () {
      return api.get(this.queryPath, {
        params: {
          ...this.queryParams,
          meta: 'count',
          page: {
            limit: 0
          }
        }
      }).then((result) => {
        this.paginationParams.total = result.data.meta.count

        itemsCountCache[this.itemsCountCacheKey] = result.data.meta.count
      }).catch((error) => {
        console.error(error)
      })
    },
    loadData () {
      this.isLoading = true

      return api.get(this.queryPath, {
        params: this.queryParams
      }).then((result) => {
        this.rows = result.data.data
      }).finally(() => {
        this.$nextTick(() => {
          this.isLoading = false
          this.isReloading = false
        })
      })
    }
  }
}
</script>